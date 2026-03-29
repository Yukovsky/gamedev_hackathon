extends Node2D
class_name Raider

enum RaiderRole {
	NORMAL,
	TANK,
	SPRINTER,
}

const TempCombatVfxScript: Script = preload("res://entities/effects/temp_combat_vfx.gd")
const TempCombatSfxScript: Script = preload("res://entities/effects/temp_combat_sfx.gd")
const ClickableComponentScript: Script = preload("res://shared/components/clickable_component.gd")
const TextureNormal: Texture2D = preload("res://assets/sprites/normal.png")
const TextureSprinter: Texture2D = preload("res://assets/sprites/sprinter.png")
const TextureTank: Texture2D = preload("res://assets/sprites/tank.png")

@export_group("Raider Movement")
@export var movement_speed_px_per_sec: float = 285.0
@export var attack_distance_px: float = 96.0
@export var retarget_interval_sec: float = 0.35
@export var path_wobble_strength: float = 0.22
@export var path_wobble_frequency_hz: float = 1.1
@export var path_wobble_strength_random_range: float = 0.12
@export var path_wobble_frequency_random_range: float = 0.3
@export var speed_random_range: float = 0.12

@export_group("Raider Attack")
@export var bite_delay_sec: float = 0.85
@export var bite_damage: int = 54

@export_group("Raider Durability")
@export var max_hp: int = 180
@export var player_tap_damage: int = 42

@export_group("Raider Roles")
@export var role_name: String = "normal"

@export_group("Raider Visual")
@export var body_size_px: float = 184.0
@export var body_color: Color = Color(0.93, 0.2, 0.2, 1.0)
@export var accent_color: Color = Color(1.0, 0.45, 0.45, 1.0)

var _board: Node
var _target: ModuleBase
var _reserved_target: ModuleBase
var _is_biting: bool = false
var _current_hp: int = 0
var _role: int = RaiderRole.NORMAL

var _retarget_timer: Timer
var _bite_timer: Timer
var _vfx: TempCombatVfx
var _sfx: TempCombatSfx
var _body_sprite: Sprite2D
var _clickable: Area2D
var _collision_shape: CollisionShape2D
var _movement_time_sec: float = 0.0
var _wobble_phase: float = 0.0
var _runtime_wobble_strength: float = 0.0
var _runtime_wobble_frequency_hz: float = 0.0
var _runtime_speed_multiplier: float = 1.0


func _ready() -> void:
	# Налетчик должен замирать на паузе вместе с остальным игровым миром.
	process_mode = Node.PROCESS_MODE_PAUSABLE

	add_to_group("raiders")
	_body_sprite = get_node_or_null("BodySprite") as Sprite2D
	_apply_role_sprite()
	if _current_hp <= 0:
		_current_hp = max(1, max_hp)
	_wobble_phase = randf() * TAU
	_runtime_wobble_strength = max(0.0, path_wobble_strength + randf_range(-path_wobble_strength_random_range, path_wobble_strength_random_range))
	_runtime_wobble_frequency_hz = max(0.05, path_wobble_frequency_hz + randf_range(-path_wobble_frequency_random_range, path_wobble_frequency_random_range))
	_runtime_speed_multiplier = max(0.85, 1.0 + randf_range(-speed_random_range, speed_random_range))

	_retarget_timer = Timer.new()
	_retarget_timer.one_shot = false
	_retarget_timer.wait_time = max(0.1, retarget_interval_sec)
	_retarget_timer.timeout.connect(_on_retarget_timeout)
	add_child(_retarget_timer)
	_retarget_timer.start()

	_bite_timer = Timer.new()
	_bite_timer.one_shot = true
	_bite_timer.wait_time = max(0.1, bite_delay_sec)
	_bite_timer.timeout.connect(_on_bite_timeout)
	add_child(_bite_timer)

	_vfx = TempCombatVfxScript.new() as TempCombatVfx
	if _vfx != null:
		if _vfx.has_method("set_palette"):
			_vfx.call("set_palette", body_color, accent_color)
		add_child(_vfx)
		_vfx.play_spawn(global_position)
	GameEvents.raider_spawned.emit(global_position)

	_sfx = TempCombatSfxScript.new() as TempCombatSfx
	if _sfx != null:
		add_child(_sfx)
		_sfx.play_spawn(global_position)

	_ensure_clickable()
	_update_click_shape()
	_clamp_to_viewport()

	queue_redraw()


func _process(delta: float) -> void:
	_movement_time_sec += delta

	if _is_biting:
		return

	if _board == null:
		_queue_despawn()
		return

	if not _is_target_valid():
		_acquire_target()

	if not _is_target_valid():
		_queue_despawn()
		return

	var target_pos: Vector2 = _target.get_world_center()
	var to_target: Vector2 = target_pos - global_position
	var distance: float = to_target.length()

	if distance <= attack_distance_px:
		_start_bite()
		return

	if distance > 0.001:
		var speed: float = movement_speed_px_per_sec * _runtime_speed_multiplier
		var move_dir: Vector2 = to_target.normalized()
		var perp_dir: Vector2 = Vector2(-move_dir.y, move_dir.x)
		var wobble: float = sin(_movement_time_sec * TAU * _runtime_wobble_frequency_hz + _wobble_phase)
		var curved_dir: Vector2 = (move_dir + perp_dir * wobble * _runtime_wobble_strength).normalized()
		global_position += curved_dir * speed * delta
		rotation = curved_dir.angle()
		_clamp_to_viewport()


func set_game_board(board: Node) -> void:
	_board = board


func configure_from_balance(balance: RaiderBalance) -> void:
	if balance == null:
		return

	movement_speed_px_per_sec = max(10.0, balance.raider_speed_px_per_sec)
	attack_distance_px = max(8.0, balance.raider_attack_distance_px)
	bite_delay_sec = max(0.1, balance.raider_bite_delay_sec)
	retarget_interval_sec = max(0.1, balance.raider_retarget_interval_sec)
	max_hp = max(1, balance.raider_max_hp)
	bite_damage = max(1, balance.raider_bite_damage)
	player_tap_damage = max(1, balance.player_tap_damage_to_raider)
	_current_hp = max_hp

	if _retarget_timer != null:
		_retarget_timer.wait_time = retarget_interval_sec
	if _bite_timer != null:
		_bite_timer.wait_time = bite_delay_sec


func configure_role_hp(role_hp: int) -> void:
	max_hp = max(1, role_hp)
	_current_hp = max_hp
	queue_redraw()


func configure_role(role: int) -> void:
	_role = clamp(role, RaiderRole.NORMAL, RaiderRole.SPRINTER)
	_apply_role_modifiers()
	_update_role_name()
	_apply_role_sprite()
	_update_click_shape()
	queue_redraw()


func _start_bite() -> void:
	if _is_biting:
		return

	_is_biting = true
	GameEvents.raider_bite.emit(global_position)
	if _sfx != null:
		_sfx.play_bite(global_position)
	if _vfx != null:
		_vfx.play_bite(global_position)
	_bite_timer.start()


func _on_bite_timeout() -> void:
	var target_world: Vector2 = global_position
	var bite_success: bool = false

	if _is_target_valid() and _board != null:
		target_world = _target.get_world_center()
		if _board.has_method("try_bite_module"):
			bite_success = bool(_board.call("try_bite_module", _target, bite_damage))

	if bite_success:
		if _vfx != null:
			_vfx.play_destroy(target_world)
		if _sfx != null:
			_sfx.play_destroy(target_world)

	_is_biting = false
	if not _is_target_valid():
		_acquire_target()


func _on_retarget_timeout() -> void:
	if not _is_target_valid():
		_acquire_target()


func _acquire_target() -> void:
	_release_reserved_target()
	_target = null
	if _board == null or not _board.has_method("get_attackable_modules"):
		return

	var modules_any: Variant = _board.call("get_attackable_modules")
	if not (modules_any is Array):
		return

	var modules: Array = modules_any as Array
	if modules.is_empty():
		return

	var best_priority: int = -999999
	var best_score: float = INF
	for candidate_any in modules:
		if not (candidate_any is ModuleBase):
			continue
		var candidate: ModuleBase = candidate_any as ModuleBase
		if not is_instance_valid(candidate):
			continue

		var candidate_priority: int = 0
		if _board.has_method("get_module_tactical_priority"):
			candidate_priority = int(_board.call("get_module_tactical_priority", candidate.module_id))
		candidate_priority += _get_role_priority_bonus(candidate.module_id)

		var distance: float = global_position.distance_to(candidate.get_world_center())
		var exposure_bonus: float = 0.0
		if _board.has_method("get_module_exposure_score"):
			var exposure_any: Variant = _board.call("get_module_exposure_score", candidate)
			var exposure: float = float(exposure_any)
			exposure_bonus = -exposure * 48.0

		var hp_bias: float = 0.0
		if candidate.has_method("get_hp_ratio"):
			var hp_ratio: float = float(candidate.call("get_hp_ratio"))
			hp_bias = hp_ratio * 64.0

		var target_pressure_penalty: float = 0.0
		if _board.has_method("get_target_pressure"):
			target_pressure_penalty = float(_board.call("get_target_pressure", candidate)) * 32.0

		var anti_core_bias: float = 0.0
		if candidate.module_id == Constants.MODULE_CORE and modules.size() > 1:
			anti_core_bias = 180.0

		var role_bias: float = _get_role_target_bias(candidate)

		var score: float = distance + exposure_bonus + hp_bias + target_pressure_penalty + anti_core_bias + role_bias
		var is_better_priority: bool = candidate_priority > best_priority
		var is_equal_priority_better_score: bool = candidate_priority == best_priority and score < best_score
		if is_better_priority or is_equal_priority_better_score:
			best_priority = candidate_priority
			best_score = score
			_target = candidate

	if _target != null and _board != null and _board.has_method("claim_module_target"):
		_board.call("claim_module_target", _target)
		_reserved_target = _target


func _is_target_valid() -> bool:
	return _target != null and is_instance_valid(_target)


func _queue_despawn() -> void:
	if is_queued_for_deletion():
		return
	_release_reserved_target()
	queue_free()


func _exit_tree() -> void:
	_release_reserved_target()


func _ensure_clickable() -> void:
	if _clickable != null and is_instance_valid(_clickable):
		return

	_clickable = Area2D.new()
	_clickable.name = "ClickableComponent"
	_clickable.script = ClickableComponentScript
	_clickable.set("one_shot", false)
	add_child(_clickable)

	_collision_shape = CollisionShape2D.new()
	_collision_shape.name = "CollisionShape2D"
	_clickable.add_child(_collision_shape)

	if _clickable.has_signal("clicked"):
		_clickable.connect("clicked", _on_tapped)


func _update_click_shape() -> void:
	if _collision_shape == null or not is_instance_valid(_collision_shape):
		return

	var circle: CircleShape2D
	if _collision_shape.shape is CircleShape2D:
		circle = _collision_shape.shape as CircleShape2D
	else:
		circle = CircleShape2D.new()
		_collision_shape.shape = circle

	circle.radius = body_size_px * 0.6


func _on_tapped() -> void:
	take_tap_damage(player_tap_damage)


func take_damage(amount: int, source: String = "unknown") -> bool:
	var damage: int = max(1, amount)
	_current_hp = max(0, _current_hp - damage)
	GameEvents.raider_damaged.emit(_current_hp, max_hp, global_position)

	if _vfx != null:
		_vfx.play_bite(global_position)
	if _sfx != null:
		_sfx.play_bite(global_position)

	queue_redraw()

	if _current_hp <= 0:
		if _vfx != null:
			_vfx.play_destroy(global_position)
		if _sfx != null:
			_sfx.play_destroy(global_position)
		GameEvents.raider_destroyed.emit(global_position, 0, source)
		queue_free()
		return true

	return false


func take_tap_damage(amount: int) -> bool:
	return take_damage(amount, "tap")


func get_hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return clamp(float(_current_hp) / float(max_hp), 0.0, 1.0)


func get_role_name() -> String:
	return role_name


func _get_role_target_bias(candidate: ModuleBase) -> float:
	match _role:
		RaiderRole.SPRINTER:
			if _board != null and _board.has_method("get_module_exposure_score"):
				var exposure: float = float(_board.call("get_module_exposure_score", candidate))
				return -exposure * 42.0
			return 0.0
		RaiderRole.TANK:
			if candidate.module_id == Constants.MODULE_REACTOR or candidate.module_id == Constants.MODULE_CORE:
				return -54.0
			return 0.0
		_:
			return 0.0


func _get_role_priority_bonus(module_id: String) -> int:
	match _role:
		RaiderRole.SPRINTER:
			if module_id == Constants.MODULE_HULL or module_id == Constants.MODULE_COLLECTOR:
				return 40
			if module_id == Constants.MODULE_TURRET:
				return -70
			return 0
		RaiderRole.TANK:
			if module_id == Constants.MODULE_REACTOR or module_id == Constants.MODULE_CORE:
				return 15
			return 0
		_:
			return 0


func _apply_role_modifiers() -> void:
	# По запросу пользователя все варианты врагов сохраняют одинаковый базовый показ
	# (масштаб, направление и движение), отличается только спрайт.
	pass


func _update_role_name() -> void:
	match _role:
		RaiderRole.TANK:
			role_name = "tank"
		RaiderRole.SPRINTER:
			role_name = "sprinter"
		_:
			role_name = "normal"


func _apply_role_sprite() -> void:
	if _body_sprite == null or not is_instance_valid(_body_sprite):
		return

	match role_name:
		"sprinter":
			_body_sprite.texture = TextureSprinter
		"tank":
			_body_sprite.texture = TextureTank
		_:
			_body_sprite.texture = TextureNormal


func _release_reserved_target() -> void:
	if _reserved_target == null:
		return
	if _board != null and _board.has_method("release_module_target"):
		_board.call("release_module_target", _reserved_target)
	_reserved_target = null


func _clamp_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var body_half: float = body_size_px * 0.5
	var hp_top_padding: float = body_size_px * 0.72 + 10.0

	var min_x: float = body_half
	var max_x: float = max(min_x, viewport_size.x - body_half)
	var min_y: float = hp_top_padding
	var max_y: float = max(min_y, viewport_size.y - body_half)

	global_position = Vector2(
		clamp(global_position.x, min_x, max_x),
		clamp(global_position.y, min_y, max_y)
	)


func _draw() -> void:
	var hp_ratio: float = get_hp_ratio()
	var hp_width: float = body_size_px * 1.1
	var hp_height: float = 10.0
	var hp_pos: Vector2 = Vector2(-hp_width * 0.5, -body_size_px * 0.72)
	draw_rect(Rect2(hp_pos, Vector2(hp_width, hp_height)), Color(0.08, 0.08, 0.08, 0.88), true)
	draw_rect(Rect2(hp_pos, Vector2(hp_width * hp_ratio, hp_height)), Color(1.0, 0.18, 0.18, 0.98), true)
