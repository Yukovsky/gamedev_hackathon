extends Node2D

@export_group("Raider Scene")
@export var raider_scene: PackedScene = preload("res://entities/raiders/raider.tscn")
@export var balance: RaiderBalance = RaiderBalance.new()

@export_group("Spawn Bounds")
@export var spawn_offset_y_px: float = 110.0
@export var spawn_margin_x_px: float = 64.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_timer: Timer
var _active_raiders: Array[Node2D] = []
var _elapsed_sec: float = 0.0
var _raiders_killed_by_tap: int = 0
var _is_game_finished: bool = false


func _ready() -> void:
	_rng.randomize()
	if GameEvents.has_signal("raider_destroyed"):
		GameEvents.raider_destroyed.connect(_on_raider_destroyed)
	if GameEvents.has_signal("game_ended"):
		GameEvents.game_ended.connect(_on_game_ended)

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.autostart = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

	_spawn_timer.wait_time = _compute_spawn_interval()


func _process(delta: float) -> void:
	if _is_game_finished:
		return

	_elapsed_sec += delta
	_cleanup_invalid_raiders()

	if _spawn_timer != null:
		_spawn_timer.wait_time = _compute_spawn_interval()


func _on_spawn_timer_timeout() -> void:
	if _is_game_finished:
		return

	if _active_raiders.size() >= _compute_max_raiders():
		return

	if _rng.randf() > _compute_spawn_chance():
		return

	_spawn_raider()


func _spawn_raider() -> void:
	if raider_scene == null:
		return

	var raider: Node2D = raider_scene.instantiate() as Node2D
	if raider == null:
		return

	var evolution_level: int = _compute_evolution_level()
	var spawn_pos: Vector2 = _compute_spawn_position(evolution_level)

	raider.global_position = spawn_pos

	if raider.has_method("configure_from_balance"):
		raider.call("configure_from_balance", balance)
	if raider.has_method("configure_evolution"):
		raider.call("configure_evolution", evolution_level, _compute_adaptation_pressure())
	if raider.has_method("configure_role"):
		raider.call("configure_role", _roll_raider_role(evolution_level))

	var board: Node = get_parent()
	if board != null and raider.has_method("set_game_board"):
		raider.call("set_game_board", board)

	add_child(raider)
	_active_raiders.append(raider)
	raider.tree_exited.connect(_on_raider_tree_exited.bind(raider))


func _compute_spawn_interval() -> float:
	if balance == null:
		return 3.0
	return max(balance.spawn_interval_min_sec, balance.spawn_interval_start_sec - balance.spawn_acceleration_per_sec * _elapsed_sec)


func _compute_spawn_chance() -> float:
	if balance == null:
		return 0.5
	return clamp(balance.spawn_chance_start + balance.spawn_chance_growth_per_sec * _elapsed_sec, 0.0, balance.spawn_chance_max)


func _compute_max_raiders() -> int:
	if balance == null:
		return 2
	var growth_steps: int = int(floor(_elapsed_sec / 90.0))
	var max_raiders: int = balance.max_raiders_start + growth_steps * max(0, balance.max_raiders_growth_per_90_sec)
	return clamp(max_raiders, balance.max_raiders_start, balance.max_raiders_cap)


func _compute_spawn_position(evolution_level: int) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var min_x: float = spawn_margin_x_px
	var max_x: float = max(spawn_margin_x_px, viewport_size.x - spawn_margin_x_px)

	var spawn_from_side_chance: float = 0.0
	if evolution_level >= 2:
		spawn_from_side_chance = 0.25
	if evolution_level >= 4:
		spawn_from_side_chance = 0.42
	if evolution_level >= 6:
		spawn_from_side_chance = 0.58

	if _rng.randf() < spawn_from_side_chance:
		var side_left: bool = _rng.randf() < 0.5
		var y: float = _rng.randf_range(spawn_margin_x_px, viewport_size.y * 0.64)
		var x: float = -spawn_offset_y_px if side_left else viewport_size.x + spawn_offset_y_px
		return Vector2(x, y)

	var spawn_x: float = _rng.randf_range(min_x, max_x)
	return Vector2(spawn_x, -spawn_offset_y_px)


func _compute_evolution_level() -> int:
	if balance == null:
		return 0

	var time_level: int = int(floor(_elapsed_sec / max(1.0, balance.evolution_step_sec)))
	var kill_blocks: int = int(floor(float(_raiders_killed_by_tap) / 6.0))
	var kill_level: int = kill_blocks * max(0, balance.evolution_level_per_6_kills)
	return clamp(time_level + kill_level, 0, balance.evolution_max_level)


func _compute_adaptation_pressure() -> float:
	if balance == null:
		return 0.0
	var value: float = float(_raiders_killed_by_tap) / 24.0
	return clamp(value, 0.0, 1.0)


func _roll_raider_role(evolution_level: int) -> int:
	var elite_chance: float = 0.12 + float(evolution_level) * 0.035
	elite_chance = clamp(elite_chance, 0.12, 0.75)

	if _rng.randf() > elite_chance:
		return Raider.RaiderRole.NORMAL

	var roll: float = _rng.randf()

	var tank_weight: float = 0.22 + float(evolution_level) * 0.01
	var sprinter_weight: float = 0.26 + float(evolution_level) * 0.008
	var sapper_weight: float = 0.28 + float(evolution_level) * 0.012
	var hacker_weight: float = 0.24 + float(evolution_level) * 0.02

	var total: float = tank_weight + sprinter_weight + sapper_weight + hacker_weight
	if total <= 0.001:
		return Raider.RaiderRole.NORMAL

	var threshold: float = tank_weight / total
	if roll < threshold:
		return Raider.RaiderRole.TANK

	threshold += sprinter_weight / total
	if roll < threshold:
		return Raider.RaiderRole.SPRINTER

	threshold += sapper_weight / total
	if roll < threshold:
		return Raider.RaiderRole.SAPPER

	return Raider.RaiderRole.HACKER


func _cleanup_invalid_raiders() -> void:
	var alive: Array[Node2D] = []
	for raider in _active_raiders:
		if is_instance_valid(raider):
			alive.append(raider)
	_active_raiders = alive


func _on_raider_tree_exited(raider: Node2D) -> void:
	_active_raiders.erase(raider)


func _on_raider_destroyed(_position: Vector2, _evolution_level: int, source: String) -> void:
	if source == "tap":
		_raiders_killed_by_tap += 1


func _on_game_ended() -> void:
	_is_game_finished = true
	if _spawn_timer != null:
		_spawn_timer.stop()

	for raider in _active_raiders:
		if is_instance_valid(raider):
			raider.queue_free()
	_active_raiders.clear()
