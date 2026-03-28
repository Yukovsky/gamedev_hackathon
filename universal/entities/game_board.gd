extends Node2D

const CELL_SIZE: float = 90.0
const CORE_START_CELL: Vector2i = Vector2i(5, 17)

const CORE_MODULE_SCRIPT: Script = preload("res://entities/modules/core_module.gd")
const COLLECTOR_MODULE_SCRIPT: Script = preload("res://entities/modules/collector_module.gd")
const REACTOR_MODULE_SCRIPT: Script = preload("res://entities/modules/reactor_module.gd")
const STORAGE_MODULE_SCRIPT: Script = preload("res://entities/modules/storage_module.gd")
const DEFENSE_MODULE_SCRIPT: Script = preload("res://entities/modules/defense_module.gd")

var gridTileManager: GridManager
var _modules_root: Node2D
var _core_module: CoreModule
var _placed_modules: Array[ModuleBase] = []
var _module_script_by_id: Dictionary = {}
var _ship_bounds_rect: Rect2 = Rect2()


func _ready() -> void:
	gridTileManager = GridManager.new()
	add_child(gridTileManager)
	gridTileManager.reset_grid()

	_module_script_by_id = {
		Constants.MODULE_COLLECTOR: COLLECTOR_MODULE_SCRIPT,
		Constants.MODULE_REACTOR: REACTOR_MODULE_SCRIPT,
		Constants.MODULE_STORAGE: STORAGE_MODULE_SCRIPT,
		Constants.MODULE_DEFENSE: DEFENSE_MODULE_SCRIPT,
	}

	_modules_root = Node2D.new()
	_modules_root.name = "ModulesRoot"
	_modules_root.position = _get_grid_origin()
	add_child(_modules_root)

	GameEvents.build_requested.connect(_on_build_requested)
	_spawn_core()

	print("GameBoard Initialized")


func _on_build_requested(module_type: String, requested_position: Vector2) -> void:
	if not _module_script_by_id.has(module_type):
		return

	var script_ref: Script = _module_script_by_id[module_type]
	var module: ModuleBase = script_ref.new() as ModuleBase
	if module == null:
		return

	var build_cell: Vector2i = _resolve_build_cell(module_type, module.grid_size, requested_position)
	if build_cell == Vector2i(-1, -1):
		return

	if not gridTileManager.canBuildAt(build_cell, module_type, module.grid_size):
		return

	var final_cost: int = _get_final_build_cost(module)
	if final_cost > 0 and not ResourceManager.spend_metal(final_cost):
		return

	_place_module(module, build_cell)
	GameEvents.module_built.emit(module_type, Vector2(build_cell))


func _spawn_core() -> void:
	var core: CoreModule = CORE_MODULE_SCRIPT.new() as CoreModule
	if core == null:
		return

	_modules_root.add_child(core)
	core.configure(CORE_START_CELL, CELL_SIZE)

	_core_module = core
	_placed_modules.append(core)
	gridTileManager.register_core(CORE_START_CELL, core.grid_size, core)
	_refresh_ship_bounds()


func _place_module(module: ModuleBase, build_cell: Vector2i) -> void:
	_modules_root.add_child(module)
	module.configure(build_cell, CELL_SIZE)

	if module is CollectorModule:
		(module as CollectorModule).set_ship_bounds_provider(_get_ship_bounds_rect)

	_update_module_facing(module)

	if module is DefenseModule and _core_module != null:
		_core_module.add_defence(module.defence_bonus)

	_placed_modules.append(module)
	gridTileManager.register_module(build_cell, module.grid_size, module.module_id, module)
	module.tree_exited.connect(_on_module_tree_exited.bind(module))
	_refresh_ship_bounds()


func _resolve_build_cell(module_type: String, module_size: Vector2i, requested_position: Vector2) -> Vector2i:
	if requested_position != Vector2.ZERO:
		var requested_cell: Vector2i = _world_to_grid(requested_position)
		if gridTileManager.canBuildAt(requested_cell, module_type, module_size):
			return requested_cell

	for y in range(GridManager.GRID_HEIGHT):
		for x in range(GridManager.GRID_WIDTH):
			var candidate: Vector2i = Vector2i(x, y)
			if gridTileManager.canBuildAt(candidate, module_type, module_size):
				return candidate

	return Vector2i(-1, -1)


func _get_final_build_cost(module: ModuleBase) -> int:
	var discount: float = 1.0
	if _core_module != null:
		discount = _core_module.get_build_discount_multiplier()

	var final_cost: int = int(ceil(float(module.metal_cost) * discount))
	if discount < 1.0 and _core_module != null:
		_core_module.consume_build_discount()

	return final_cost


func _world_to_grid(world_position: Vector2) -> Vector2i:
	var local_position: Vector2 = world_position - _modules_root.position
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
	if _core_module == null:
		return

	var direction_from_core: Vector2 = module.get_world_center() - _core_module.get_world_center()
	if direction_from_core == Vector2.ZERO:
		return

	var cardinal_direction: Vector2 = _to_cardinal(direction_from_core.normalized())
	module.set_facing_direction(cardinal_direction)


func _to_cardinal(direction: Vector2) -> Vector2:
	if abs(direction.x) > abs(direction.y):
		return Vector2(sign(direction.x), 0)
	return Vector2(0, sign(direction.y))


func _refresh_ship_bounds() -> void:
	var has_rect: bool = false
	var merged_rect: Rect2 = Rect2()

	for module in _placed_modules:
		if not is_instance_valid(module):
			continue

		var module_rect: Rect2 = Rect2(
			module.global_position,
			Vector2(module.grid_size.x, module.grid_size.y) * CELL_SIZE
		)

		if not has_rect:
			has_rect = true
			merged_rect = module_rect
		else:
			merged_rect = merged_rect.merge(module_rect)

	_ship_bounds_rect = merged_rect if has_rect else Rect2()


func _get_ship_bounds_rect() -> Rect2:
	return _ship_bounds_rect


func _on_module_tree_exited(module: ModuleBase) -> void:
	_placed_modules.erase(module)
	gridTileManager.unregister_module(module)
	_refresh_ship_bounds()
