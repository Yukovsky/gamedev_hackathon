extends Node2D

@export_group("Raider Scene")
@export var raider_scene: PackedScene = preload("res://entities/raiders/raider.tscn")
@export var balance: RaiderBalance = RaiderBalance.new()
@export var spawn_interval_sec: float = 1.2
@export var min_buildings_for_spawn: int = 2

@export_group("Spawn Bounds")
@export var spawn_offset_y_px: float = 110.0
@export var spawn_margin_x_px: float = 64.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_timer: Timer
var _active_raiders: Array[Node2D] = []
var _is_game_finished: bool = false
var _spawn_cycle: Array[int] = []
var _spawn_cycle_index: int = 0
var _spawn_cycle_key: String = ""
var _spawn_enabled_by_buildings: bool = false

const BALANCE_ROWS: Array[Dictionary] = [
	{
		"buildings_min": 0,
		"buildings_max": 1,
		"enemy_set": [],
		"normal_hp": 0,
		"sprinter_hp": 0,
		"tank_hp": 0,
		"max_active": 0,
	},
	{
		"buildings_min": 2,
		"buildings_max": 2,
		"enemy_set": [{"type": "normal", "count": 1}],
		"normal_hp": 153,
		"sprinter_hp": 0,
		"tank_hp": 0,
		"max_active": 1,
	},
	{
		"buildings_min": 3,
		"buildings_max": 3,
		"enemy_set": [{"type": "normal", "count": 1}],
		"normal_hp": 162,
		"sprinter_hp": 0,
		"tank_hp": 0,
		"max_active": 1,
	},
	{
		"buildings_min": 4,
		"buildings_max": 4,
		"enemy_set": [{"type": "normal", "count": 2}],
		"normal_hp": 171,
		"sprinter_hp": 0,
		"tank_hp": 0,
		"max_active": 1,
	},
	{
		"buildings_min": 5,
		"buildings_max": 5,
		"enemy_set": [{"type": "normal", "count": 1}, {"type": "sprinter", "count": 1}],
		"normal_hp": 180,
		"sprinter_hp": 130,
		"tank_hp": 0,
		"max_active": 2,
	},
	{
		"buildings_min": 6,
		"buildings_max": 6,
		"enemy_set": [{"type": "normal", "count": 2}, {"type": "sprinter", "count": 1}],
		"normal_hp": 189,
		"sprinter_hp": 137,
		"tank_hp": 0,
		"max_active": 2,
	},
	{
		"buildings_min": 7,
		"buildings_max": 7,
		"enemy_set": [{"type": "normal", "count": 1}, {"type": "sprinter", "count": 1}, {"type": "tank", "count": 1}],
		"normal_hp": 198,
		"sprinter_hp": 143,
		"tank_hp": 446,
		"max_active": 2,
	},
	{
		"buildings_min": 8,
		"buildings_max": 8,
		"enemy_set": [{"type": "normal", "count": 2}, {"type": "sprinter", "count": 1}, {"type": "tank", "count": 1}],
		"normal_hp": 207,
		"sprinter_hp": 150,
		"tank_hp": 466,
		"max_active": 3,
	},
	{
		"buildings_min": 9,
		"buildings_max": 9,
		"enemy_set": [{"type": "normal", "count": 2}, {"type": "sprinter", "count": 2}, {"type": "tank", "count": 1}],
		"normal_hp": 216,
		"sprinter_hp": 156,
		"tank_hp": 486,
		"max_active": 3,
	},
	{
		"buildings_min": 10,
		"buildings_max": 999,
		"enemy_set": [{"type": "normal", "count": 2}, {"type": "sprinter", "count": 2}, {"type": "tank", "count": 2}],
		"normal_hp": 225,
		"sprinter_hp": 163,
		"tank_hp": 506,
		"max_active": 3,
	},
]


func _ready() -> void:
	# Спавнер и его таймеры должны останавливаться на глобальной паузе.
	process_mode = Node.PROCESS_MODE_PAUSABLE

	_rng.randomize()
	if GameEvents.has_signal("game_ended"):
		GameEvents.game_ended.connect(_on_game_ended)
	if GameEvents.has_signal("module_built"):
		GameEvents.module_built.connect(_on_buildings_changed)
	if GameEvents.has_signal("module_destroyed"):
		GameEvents.module_destroyed.connect(_on_buildings_changed)
	if GameEvents.has_signal("tutorial_raider_spawn_requested"):
		GameEvents.tutorial_raider_spawn_requested.connect(_on_tutorial_raider_spawn_requested)

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.autostart = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	_spawn_timer.wait_time = max(0.15, spawn_interval_sec)
	_spawn_timer.start()
	_sync_spawn_timer_state()


func _process(_delta: float) -> void:
	if _is_game_finished:
		return
	_cleanup_invalid_raiders()


func _on_spawn_timer_timeout() -> void:
	if _is_game_finished:
		return
	var buildings_count: int = _sync_spawn_timer_state()
	if not _spawn_enabled_by_buildings:
		return
	_cleanup_invalid_raiders()

	var row: Dictionary = _get_balance_row(buildings_count)
	if int(row.get("max_active", 0)) <= 0:
		return
	if _active_raiders.size() >= int(row.get("max_active", 0)):
		return

	_spawn_raider(row)


func _on_buildings_changed(_module_type: String, _position: Vector2) -> void:
	_reset_spawn_cycle()
	_sync_spawn_timer_state()


func _sync_spawn_timer_state() -> int:
	var buildings_count: int = _get_current_buildings_count()
	_spawn_enabled_by_buildings = buildings_count >= max(1, min_buildings_for_spawn)

	if _spawn_timer != null:
		if _spawn_enabled_by_buildings:
			if _spawn_timer.is_stopped():
				_spawn_timer.start()
		else:
			if not _spawn_timer.is_stopped():
				_spawn_timer.stop()

	return buildings_count


func _spawn_raider(row: Dictionary) -> void:
	if raider_scene == null:
		return

	var raider: Node2D = raider_scene.instantiate() as Node2D
	if raider == null:
		return

	var role: int = _next_role_for_row(row)
	var hp: int = _hp_for_role(row, role)
	var spawn_pos: Vector2 = _compute_spawn_position(role)

	raider.global_position = spawn_pos

	if raider.has_method("configure_from_balance"):
		raider.call("configure_from_balance", balance)
	if raider.has_method("configure_role"):
		raider.call("configure_role", role)
	if raider.has_method("configure_role_hp"):
		raider.call("configure_role_hp", hp)

	var board: Node = get_parent()
	if board != null and raider.has_method("set_game_board"):
		raider.call("set_game_board", board)

	add_child(raider)
	_active_raiders.append(raider)
	raider.tree_exited.connect(_on_raider_tree_exited.bind(raider))


func _get_current_buildings_count() -> int:
	var board: Node = get_parent()
	if board == null:
		return 0

	if board.has_method("get_raider_balance_buildings_count"):
		return max(0, int(board.call("get_raider_balance_buildings_count")))

	if board.has_method("get_attackable_modules"):
		var modules_any: Variant = board.call("get_attackable_modules")
		if modules_any is Array:
			var result: int = 0
			for module_any in modules_any:
				if module_any is ModuleBase:
					var module: ModuleBase = module_any as ModuleBase
					if module.module_id != Constants.MODULE_CORE:
						result += 1
			return result

	return 0


func _get_balance_row(buildings_count: int) -> Dictionary:
	for row in BALANCE_ROWS:
		var min_b: int = int(row.get("buildings_min", 0))
		var max_b: int = int(row.get("buildings_max", 0))
		if buildings_count >= min_b and buildings_count <= max_b:
			return row
	return BALANCE_ROWS[BALANCE_ROWS.size() - 1]


func _next_role_for_row(row: Dictionary) -> int:
	var enemy_set: Array = row.get("enemy_set", []) as Array
	var cycle_key: String = str(row.get("buildings_min", 0)) + ":" + str(row.get("buildings_max", 0)) + ":" + str(enemy_set)
	if _spawn_cycle.is_empty() or _spawn_cycle_key != cycle_key or _spawn_cycle_index >= _spawn_cycle.size():
		_spawn_cycle_key = cycle_key
		_spawn_cycle = _build_spawn_cycle(enemy_set)
		_spawn_cycle_index = 0

	if _spawn_cycle.is_empty():
		return Raider.RaiderRole.NORMAL

	var role: int = _spawn_cycle[_spawn_cycle_index]
	_spawn_cycle_index += 1
	return role


func _build_spawn_cycle(enemy_set: Array) -> Array[int]:
	var roles: Array[int] = []
	for entry_any in enemy_set:
		if not (entry_any is Dictionary):
			continue
		var entry: Dictionary = entry_any as Dictionary
		var role: int = _role_from_type_name(String(entry.get("type", "normal")))
		var count: int = max(0, int(entry.get("count", 0)))
		for _i in range(count):
			roles.append(role)

	if roles.is_empty():
		roles.append(Raider.RaiderRole.NORMAL)

	for i in range(roles.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: int = roles[i]
		roles[i] = roles[j]
		roles[j] = tmp

	return roles


func _role_from_type_name(type_name: String) -> int:
	match type_name.to_lower():
		"sprinter":
			return Raider.RaiderRole.SPRINTER
		"tank":
			return Raider.RaiderRole.TANK
		_:
			return Raider.RaiderRole.NORMAL


func _hp_for_role(row: Dictionary, role: int) -> int:
	match role:
		Raider.RaiderRole.SPRINTER:
			return max(1, int(row.get("sprinter_hp", 1)))
		Raider.RaiderRole.TANK:
			return max(1, int(row.get("tank_hp", 1)))
		_:
			return max(1, int(row.get("normal_hp", 1)))


func _compute_spawn_position(role: int) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var min_x: float = spawn_margin_x_px
	var max_x: float = max(spawn_margin_x_px, viewport_size.x - spawn_margin_x_px)
	var spawn_from_side_chance: float = 0.18

	if role == Raider.RaiderRole.SPRINTER:
		spawn_from_side_chance = 0.48
	elif role == Raider.RaiderRole.TANK:
		spawn_from_side_chance = 0.1

	if _rng.randf() < spawn_from_side_chance:
		var side_left: bool = _rng.randf() < 0.5
		var y: float = _rng.randf_range(spawn_margin_x_px, viewport_size.y * 0.64)
		var x: float = -spawn_offset_y_px if side_left else viewport_size.x + spawn_offset_y_px
		return Vector2(x, y)

	var spawn_x: float = _rng.randf_range(min_x, max_x)
	return Vector2(spawn_x, -spawn_offset_y_px)


func _reset_spawn_cycle() -> void:
	_spawn_cycle.clear()
	_spawn_cycle_index = 0
	_spawn_cycle_key = ""


func _cleanup_invalid_raiders() -> void:
	var alive: Array[Node2D] = []
	for raider in _active_raiders:
		if is_instance_valid(raider):
			alive.append(raider)
	_active_raiders = alive


func _on_raider_tree_exited(raider: Node2D) -> void:
	_active_raiders.erase(raider)


func _on_game_ended() -> void:
	_is_game_finished = true
	if _spawn_timer != null:
		_spawn_timer.stop()

	for raider in _active_raiders:
		if is_instance_valid(raider):
			raider.queue_free()
	_active_raiders.clear()


func _on_tutorial_raider_spawn_requested() -> void:
	if _is_game_finished:
		return
	_cleanup_invalid_raiders()
	if not _active_raiders.is_empty():
		return

	var row: Dictionary = _get_balance_row(_get_current_buildings_count())
	var tutorial_row: Dictionary = row.duplicate(true)
	if int(tutorial_row.get("max_active", 0)) <= 0:
		tutorial_row["max_active"] = 1
	if not tutorial_row.has("enemy_set") or (tutorial_row.get("enemy_set") as Array).is_empty():
		tutorial_row["enemy_set"] = [{"type": "normal", "count": 1}]
	if int(tutorial_row.get("normal_hp", 0)) <= 0:
		tutorial_row["normal_hp"] = max(1, balance.raider_max_hp)

	_spawn_raider(tutorial_row)
