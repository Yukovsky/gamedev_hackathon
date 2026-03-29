extends Node2D

const CELL_SIZE: float = float(GridManager.CELL_SIZE)
const CORE_START_CELL: Vector2i = Vector2i(5, 17)

const CORE_MODULE_SCRIPT: Script = preload("res://entities/modules/core_module.gd")
const COLLECTOR_MODULE_SCRIPT: Script = preload("res://entities/modules/collector_module.gd")
const REACTOR_MODULE_SCRIPT: Script = preload("res://entities/modules/reactor_module.gd")
const HULL_MODULE_SCRIPT: Script = preload("res://entities/modules/hull_module.gd")
const TURRET_MODULE_SCRIPT: Script = preload("res://entities/modules/turret_module.gd")

var gridTileManager: GridManager
var _modules_root: Node2D
var _highlights_root: Node2D
var _core_module: CoreModule
var _placed_modules: Array[ModuleBase] = []
var _module_script_by_id: Dictionary = {}
var _ship_bounds_rect: Rect2 = Rect2()
var _target_pressure_by_module: Dictionary = {}
var _is_game_finished: bool = false
var _is_collapsing_unattached: bool = false

# Состояние постройки
var _active_build_type: String = ""
var _active_build_size: Vector2i = Vector2i.ONE

func _ready() -> void:
	# Позволяет ставить модули из магазина во время паузы.
	process_mode = Node.PROCESS_MODE_ALWAYS

	gridTileManager = GridManager.new()
	gridTileManager.name = "GridManager" # Чтобы SaveManager его нашел
	add_child(gridTileManager)
	gridTileManager.reset_grid()

	var debris_spawner: Node = get_node_or_null("DebrisSpawner")
	if debris_spawner != null:
		debris_spawner.process_mode = Node.PROCESS_MODE_PAUSABLE

	_module_script_by_id = {
		Constants.MODULE_COLLECTOR: COLLECTOR_MODULE_SCRIPT,
		Constants.MODULE_REACTOR: REACTOR_MODULE_SCRIPT,
		Constants.MODULE_HULL: HULL_MODULE_SCRIPT,
		Constants.MODULE_TURRET: TURRET_MODULE_SCRIPT,
	}

	_highlights_root = Node2D.new()
	_highlights_root.name = "HighlightsRoot"
	add_child(_highlights_root)

	_modules_root = Node2D.new()
	_modules_root.name = "ModulesRoot"
	_modules_root.position = _get_grid_origin()
	_modules_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	_highlights_root.position = _modules_root.position
	add_child(_modules_root)

	GameEvents.build_requested.connect(_on_build_requested)
	_spawn_core()

	print("GameBoard Initialized at origin: ", _modules_root.position)

func _unhandled_input(event: InputEvent) -> void:
	if _is_game_finished:
		return
	if _active_build_type == "": return

	var pointer_pos: Vector2
	var has_pointer_press: bool = false

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			has_pointer_press = true
			pointer_pos = mouse_event.position
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			has_pointer_press = true
			pointer_pos = touch_event.position

	if not has_pointer_press:
		return

	var grid_pos: Vector2i = _world_to_grid(pointer_pos)

	# Пытаемся построить. Если успешно — режим сбросится сам внутри _try_place_module_at
	if _try_place_module_at(_active_build_type, grid_pos):
		print("Build Successful at ", grid_pos)
	else:
		# Если кликнули ВНУТРИ сетки, но мимо подсветки — отменяем режим
		if grid_pos.x >= 0 and grid_pos.x < GridManager.GRID_WIDTH and \
		   grid_pos.y >= 0 and grid_pos.y < GridManager.GRID_HEIGHT:
			var cancelled_type: String = _active_build_type
			_clear_highlights()
			GameEvents.build_mode_cancelled.emit(cancelled_type)
			print("Build cancelled by clicking empty grid")

func _on_build_requested(module_type: String, requested_position: Vector2) -> void:
	if _is_game_finished:
		return
	if not _module_script_by_id.has(module_type): return
	if requested_position == Vector2.ZERO:
		_enter_build_mode(module_type)
	else:
		var grid_pos = _world_to_grid(requested_position)
		_try_place_module_at(module_type, grid_pos)


func is_build_mode_active() -> bool:
	return _active_build_type != ""

func _enter_build_mode(module_type: String) -> void:
	_clear_highlights()
	_active_build_type = module_type
	var script_ref: Script = _module_script_by_id[module_type]
	var temp_module: ModuleBase = script_ref.new() as ModuleBase
	_active_build_size = temp_module.grid_size
	temp_module.queue_free()
	_show_valid_placements(module_type, _active_build_size)

func _clear_highlights() -> void:
	for child in _highlights_root.get_children():
		child.queue_free()
	_active_build_type = ""

func _show_valid_placements(type: String, size: Vector2i) -> void:
	var count = 0
	for y in range(GridManager.GRID_HEIGHT):
		for x in range(GridManager.GRID_WIDTH):
			var pos = Vector2i(x, y)
			if gridTileManager.canBuildAt(pos, type, size):
				_create_highlight(pos, size)
				count += 1
	print("Found ", count, " valid placements for ", type)

func _create_highlight(pos: Vector2i, size: Vector2i) -> void:
	var rect = ColorRect.new()
	rect.color = Color(0.5, 0.5, 0.5, 0.4)
	rect.size = Vector2(size.x * CELL_SIZE - 4, size.y * CELL_SIZE - 4)
	rect.position = Vector2(pos.x * CELL_SIZE + 2, pos.y * CELL_SIZE + 2)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlights_root.add_child(rect)

func _try_place_module_at(module_type: String, build_cell: Vector2i) -> bool:
	if module_type == "": return false
	
	var script_ref: Script = _module_script_by_id[module_type]
	var module: ModuleBase = script_ref.new() as ModuleBase
	
	if not gridTileManager.canBuildAt(build_cell, module_type, module.grid_size):
		module.queue_free()
		return false

	var discount_used: bool = _core_module != null and _core_module.get_build_discount_multiplier() < 1.0
	var final_cost: int = _get_final_build_cost(module)
	if final_cost > 0 and not ResourceManager.spend_metal(final_cost):
		print("Not enough metal! Need: ", final_cost)
		module.queue_free()
		return false

	_place_module(module, build_cell)
	if discount_used and _core_module != null:
		_core_module.consume_build_discount()
	GameEvents.module_built.emit(module_type, Vector2(build_cell))
	_clear_highlights()
	return true

func _spawn_core() -> void:
	var core: CoreModule = CORE_MODULE_SCRIPT.new() as CoreModule
	_modules_root.add_child(core)
	core.configure(CORE_START_CELL, CELL_SIZE)
	core.destroy_requested.connect(_on_module_destroy_requested)
	_core_module = core
	_placed_modules.append(core)
	gridTileManager.register_core(CORE_START_CELL, core.grid_size, core)
	_refresh_ship_bounds()

func _place_module(module: ModuleBase, build_cell: Vector2i) -> void:
	_modules_root.add_child(module)
	module.configure(build_cell, CELL_SIZE)
	
	# Безопасная проверка типа модуля (чтобы не было ошибок каста)
	if module.module_id == Constants.MODULE_COLLECTOR and module.has_method("set_ship_bounds_provider"):
		module.set_ship_bounds_provider(_get_ship_bounds_rect)

	_update_module_facing(module)



	_placed_modules.append(module)
	module.destroy_requested.connect(_on_module_destroy_requested)
	gridTileManager.register_module(build_cell, module.grid_size, module.module_id, module)
	module.tree_exited.connect(_on_module_tree_exited.bind(module))
	_refresh_ship_bounds()
	_check_win_condition()

func _get_final_build_cost(module: ModuleBase) -> int:
	var discount: float = 1.0
	if _core_module != null:
		discount = _core_module.get_build_discount_multiplier()
	var base_cost: int = ResourceManager.get_current_module_cost(module.module_id)
	if base_cost <= 0:
		base_cost = module.metal_cost
	return int(ceil(float(base_cost) * discount))

func _world_to_grid(world_position: Vector2) -> Vector2i:
	var local_position: Vector2 = world_position - _modules_root.global_position
	return Vector2i(
		int(floor(local_position.x / CELL_SIZE)),
		int(floor(local_position.y / CELL_SIZE))
	)

func _get_grid_origin() -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var grid_pixel_size: Vector2 = Vector2(GridManager.GRID_WIDTH, GridManager.GRID_HEIGHT) * CELL_SIZE
	return Vector2(
		(viewport_size.x - grid_pixel_size.x) * 0.5,
		viewport_size.y - grid_pixel_size.y
	)

func _update_module_facing(module: ModuleBase) -> void:
	if _core_module == null: return
	var direction_from_core: Vector2 = module.get_world_center() - _core_module.get_world_center()
	if direction_from_core == Vector2.ZERO: return
	module.set_facing_direction(_to_cardinal(direction_from_core.normalized()))

func _to_cardinal(direction: Vector2) -> Vector2:
	if abs(direction.x) > abs(direction.y):
		return Vector2(sign(direction.x), 0)
	return Vector2(0, sign(direction.y))

func _refresh_ship_bounds() -> void:
	var has_rect: bool = false
	var merged_rect: Rect2 = Rect2()
	for module in _placed_modules:
		if not is_instance_valid(module): continue
		var module_rect: Rect2 = Rect2(module.global_position, Vector2(module.grid_size.x, module.grid_size.y) * CELL_SIZE)
		if not has_rect:
			has_rect = true
			merged_rect = module_rect
		else:
			merged_rect = merged_rect.merge(module_rect)
	_ship_bounds_rect = merged_rect if has_rect else Rect2()

func _get_ship_bounds_rect() -> Rect2:
	return _ship_bounds_rect

func _on_module_tree_exited(module: ModuleBase) -> void:
	_target_pressure_by_module.erase(module)
	_placed_modules.erase(module)
	gridTileManager.unregister_module(module)
	if module == _core_module:
		_core_module = null
	_refresh_ship_bounds()
	if not _is_game_finished and not _is_collapsing_unattached:
		call_deferred("_collapse_unattached_modules")


func _on_module_destroy_requested(module: ModuleBase, source: String) -> void:
	_destroy_module(module, source)


func _destroy_module(module: ModuleBase, source: String) -> bool:
	if _is_game_finished:
		return false

	if module == null or not is_instance_valid(module):
		return false

	if not _placed_modules.has(module):
		return false



	var destroyed_module_id: String = module.module_id
	var destroyed_pos: Vector2 = Vector2(module.grid_position)
	module.queue_free()
	GameEvents.module_destroyed.emit(destroyed_module_id, destroyed_pos)

	if module == _core_module:
		_is_game_finished = true
		var reason: String = "core_destroyed"
		if source == "raider":
			reason = "core_eaten_by_raiders"
		GameEvents.game_finished.emit("lose", reason)
		GameEvents.game_ended.emit()
	else:
		if not _is_collapsing_unattached:
			call_deferred("_collapse_unattached_modules")

	return true


func _check_win_condition() -> void:
	if _is_game_finished:
		return

	var reactor_count: int = 0
	for module in _placed_modules:
		if not is_instance_valid(module):
			continue
		if module.module_id == Constants.MODULE_REACTOR:
			reactor_count += 1

	if reactor_count >= 4:
		_is_game_finished = true
		GameEvents.game_finished.emit("win", "reactors_4")
		GameEvents.game_ended.emit()


func get_attackable_modules() -> Array[ModuleBase]:
	var result: Array[ModuleBase] = []
	for module in _placed_modules:
		if not is_instance_valid(module):
			continue
		if module == _core_module:
			continue
		result.append(module)

	if result.is_empty() and _core_module != null and is_instance_valid(_core_module):
		result.append(_core_module)

	return result


func get_raider_balance_buildings_count() -> int:
	var count: int = 0
	for module in _placed_modules:
		if not is_instance_valid(module):
			continue
		if module == _core_module:
			continue
		count += 1
	return count


func get_module_exposure_score(module: ModuleBase) -> int:
	if module == null or not is_instance_valid(module):
		return 0

	var occupied: Dictionary = gridTileManager.get_occupied_cells()
	var directions: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT,
	]

	var exposed_edges: int = 0
	for cell in module.get_occupied_cells():
		for dir in directions:
			var neighbour: Vector2i = cell + dir
			if neighbour.x < 0 or neighbour.y < 0 or neighbour.x >= GridManager.GRID_WIDTH or neighbour.y >= GridManager.GRID_HEIGHT:
				exposed_edges += 1
			elif not occupied.has(neighbour):
				exposed_edges += 1

	return exposed_edges


func try_bite_module(module: ModuleBase, damage: int = 1) -> bool:
	if module == null or not is_instance_valid(module):
		return false

	if not _placed_modules.has(module):
		return false

	if module.has_method("take_damage"):
		var was_destroyed: bool = bool(module.call("take_damage", max(1, damage), "raider"))
		return was_destroyed

	return _destroy_module(module, "raider")


func get_module_tactical_priority(module_id: String) -> int:
	match module_id:
		Constants.MODULE_TURRET:
			return 100
		Constants.MODULE_REACTOR:
			return 50
		Constants.MODULE_COLLECTOR:
			return 40
		Constants.MODULE_HULL:
			return 20
		Constants.MODULE_CORE:
			return 10
		_:
			return 0


func claim_module_target(module: ModuleBase) -> void:
	if module == null or not is_instance_valid(module):
		return
	_target_pressure_by_module[module] = int(_target_pressure_by_module.get(module, 0)) + 1


func release_module_target(module: ModuleBase) -> void:
	if module == null:
		return
	if not _target_pressure_by_module.has(module):
		return
	var next_value: int = int(_target_pressure_by_module[module]) - 1
	if next_value <= 0:
		_target_pressure_by_module.erase(module)
	else:
		_target_pressure_by_module[module] = next_value


func get_target_pressure(module: ModuleBase) -> int:
	if module == null:
		return 0
	return int(_target_pressure_by_module.get(module, 0))


func _collapse_unattached_modules() -> void:
	if _is_game_finished:
		return
	if _core_module == null or not is_instance_valid(_core_module):
		return
	if _is_collapsing_unattached:
		return

	_is_collapsing_unattached = true

	var occupied: Dictionary = gridTileManager.get_occupied_cells()
	if occupied.is_empty():
		_is_collapsing_unattached = false
		return

	var visited_cells: Dictionary = {}
	var queue: Array[Vector2i] = []
	for core_cell in _core_module.get_occupied_cells():
		if occupied.has(core_cell):
			visited_cells[core_cell] = true
			queue.append(core_cell)

	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for dir in dirs:
			var n: Vector2i = cell + dir
			if visited_cells.has(n):
				continue
			if occupied.has(n):
				visited_cells[n] = true
				queue.append(n)

	var to_collapse: Array[ModuleBase] = []
	for module in _placed_modules:
		if not is_instance_valid(module):
			continue
		if module == _core_module:
			continue

		var connected: bool = false
		for c in module.get_occupied_cells():
			if visited_cells.has(c):
				connected = true
				break

		if not connected:
			to_collapse.append(module)

	for module in to_collapse:
		_destroy_module(module, "collapse")

	_is_collapsing_unattached = false
