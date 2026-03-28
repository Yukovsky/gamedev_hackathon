extends "res://entities/modules/module_base.gd"
class_name TurretModule

enum TargetMode {
	NEAREST,
	LOWEST_HP,
	ADAPTIVE,
}

@export var fire_cooldown_sec: float = 0.42
@export var attack_range_cells: float = 4.8
@export var turret_damage: int = 34
@export var target_mode: TargetMode = TargetMode.ADAPTIVE
@export var lock_on_bonus_damage: int = 8
@export var lock_on_after_shots: int = 3
@export var burst_shots: int = 2
@export var burst_interval_sec: float = 0.08
@export var heat_per_shot: float = 0.16
@export var cool_per_sec: float = 0.42
@export var overheat_threshold: float = 1.0
@export var cooldown_resume_threshold: float = 0.35
@export var laser_color: Color = Color(1.0, 0.35, 0.15, 1.0)
@export var hacked_tint: Color = Color(0.3, 0.95, 0.95, 1.0)

var _fire_timer: Timer
var _burst_timer: Timer
var _laser_hide_timer: Timer
var _laser: Line2D
var _current_target: Node2D
var _consecutive_hits_on_target: int = 0
var _shots_left_in_burst: int = 0
var _heat: float = 0.0
var _is_overheated: bool = false
var _hack_disabled_time_left_sec: float = 0.0
var _base_sprite_color: Color = Color.WHITE


func _init() -> void:
	module_id = Constants.MODULE_TURRET
	grid_size = Vector2i.ONE
	metal_cost = Constants.get_module_cost(module_id)
	max_hp = 200
	tap_damage = 32
	sprite_color = Color(0.95, 0.32, 0.18, 1.0)
	_base_sprite_color = sprite_color


func _ready() -> void:
	_fire_timer = Timer.new()
	_fire_timer.one_shot = false
	_fire_timer.wait_time = max(0.1, fire_cooldown_sec)
	_fire_timer.timeout.connect(_on_fire_timer)
	add_child(_fire_timer)
	_fire_timer.start()

	_burst_timer = Timer.new()
	_burst_timer.one_shot = false
	_burst_timer.wait_time = max(0.01, burst_interval_sec)
	_burst_timer.timeout.connect(_on_burst_timer)
	add_child(_burst_timer)

	_laser_hide_timer = Timer.new()
	_laser_hide_timer.one_shot = true
	_laser_hide_timer.wait_time = 0.08
	_laser_hide_timer.timeout.connect(_hide_laser)
	add_child(_laser_hide_timer)

	_laser = Line2D.new()
	_laser.width = 4.0
	_laser.default_color = laser_color
	_laser.visible = false
	add_child(_laser)


func _process(delta: float) -> void:
	if _hack_disabled_time_left_sec > 0.0:
		_hack_disabled_time_left_sec = max(0.0, _hack_disabled_time_left_sec - delta)
		if _hack_disabled_time_left_sec <= 0.0:
			sprite_color = _base_sprite_color
			queue_redraw()

	if _heat > 0.0:
		_heat = max(0.0, _heat - cool_per_sec * delta)

	if _is_overheated and _heat <= cooldown_resume_threshold:
		_is_overheated = false


func _on_fire_timer() -> void:
	if _is_build_mode_active():
		return
	if _is_hacked_disabled():
		return
	if _is_overheated:
		return
	if _burst_timer != null and not _burst_timer.is_stopped():
		return

	_current_target = _find_target()
	if _current_target == null:
		_consecutive_hits_on_target = 0
		return

	_shots_left_in_burst = max(1, burst_shots)
	_fire_single_shot(_current_target)
	_shots_left_in_burst -= 1

	if _shots_left_in_burst > 0:
		_burst_timer.start()


func _on_burst_timer() -> void:
	if _is_build_mode_active() or _is_overheated or _is_hacked_disabled():
		_burst_timer.stop()
		return

	if _shots_left_in_burst <= 0:
		_burst_timer.stop()
		return

	if _current_target == null or not is_instance_valid(_current_target):
		_current_target = _find_target()
		if _current_target == null:
			_burst_timer.stop()
			_consecutive_hits_on_target = 0
			return

	var center: Vector2 = get_world_center()
	var range_px: float = attack_range_cells * cell_size_px
	if center.distance_to(_current_target.global_position) > range_px:
		_current_target = _find_target()
		if _current_target == null:
			_burst_timer.stop()
			_consecutive_hits_on_target = 0
			return

	_fire_single_shot(_current_target)
	_shots_left_in_burst -= 1

	if _shots_left_in_burst <= 0:
		_burst_timer.stop()


func _fire_single_shot(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	_show_laser_to(target.global_position)
	AudioManager.play_turret_shot()

	var damage: int = turret_damage
	if _consecutive_hits_on_target >= max(1, lock_on_after_shots):
		damage += max(0, lock_on_bonus_damage)

	if target.has_method("take_damage"):
		target.call("take_damage", damage, "turret")
	elif target.has_method("take_tap_damage"):
		target.call("take_tap_damage", damage)

	_heat += max(0.02, heat_per_shot)
	if _heat >= overheat_threshold:
		_is_overheated = true

	if _current_target == target:
		_consecutive_hits_on_target += 1
	else:
		_current_target = target
		_consecutive_hits_on_target = 1


func _find_target() -> Node2D:
	var raiders: Array = get_tree().get_nodes_in_group("raiders")
	if raiders.is_empty():
		return null

	var range_px: float = attack_range_cells * cell_size_px
	var center: Vector2 = get_world_center()

	var best_target: Node2D = null
	var best_score: float = INF
	for node in raiders:
		if not (node is Node2D):
			continue
		var raider: Node2D = node as Node2D
		if not is_instance_valid(raider):
			continue

		var distance: float = center.distance_to(raider.global_position)
		if distance > range_px:
			continue

		var score: float = distance
		if target_mode == TargetMode.LOWEST_HP and raider.has_method("get_hp_ratio"):
			var hp_ratio: float = float(raider.call("get_hp_ratio"))
			score = hp_ratio * 1000.0 + distance
		elif target_mode == TargetMode.ADAPTIVE:
			var hp_factor: float = 0.0
			if raider.has_method("get_hp_ratio"):
				hp_factor = float(raider.call("get_hp_ratio")) * 520.0

			var lock_bonus: float = 0.0
			if raider == _current_target:
				lock_bonus = -220.0

			score = distance + hp_factor + lock_bonus

		if score < best_score:
			best_score = score
			best_target = raider

	return best_target


func _show_laser_to(target_world: Vector2) -> void:
	var origin: Vector2 = Vector2(grid_size.x * cell_size_px * 0.5, grid_size.y * cell_size_px * 0.5)
	var target_local: Vector2 = to_local(target_world)
	_laser.points = PackedVector2Array([origin, target_local])
	_laser.visible = true
	_laser_hide_timer.start()


func _hide_laser() -> void:
	_laser.visible = false


func _is_build_mode_active() -> bool:
	var cursor: Node = get_parent()
	while cursor != null:
		if cursor.has_method("is_build_mode_active"):
			return bool(cursor.call("is_build_mode_active"))
		cursor = cursor.get_parent()
	return false


func apply_hack_disable(duration_sec: float) -> void:
	_hack_disabled_time_left_sec = max(_hack_disabled_time_left_sec, max(0.3, duration_sec))
	sprite_color = hacked_tint
	_consecutive_hits_on_target = 0
	_current_target = null
	if _burst_timer != null:
		_burst_timer.stop()
	_hide_laser()
	queue_redraw()


func _is_hacked_disabled() -> bool:
	return _hack_disabled_time_left_sec > 0.0
