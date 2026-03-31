extends Node
class_name BuildModeController
## Контроллер режима постройки модулей.
## Управляет подсветкой допустимых позиций, обработкой клика и размещением.

signal build_executed(module_type: String, grid_pos: Vector2i, success: bool)

@export var highlights_root: Node2D
@export var grid_manager: GridManager

var _active_build_type: String = ""
var _active_build_size: Vector2i = Vector2i.ONE
var _module_script_by_id: Dictionary = {}
var _cell_size: float = 90.0
var _is_enabled: bool = true


func _ready() -> void:
	GameEvents.build_requested.connect(_on_build_requested)


func configure(
	cell_size: float,
	module_scripts: Dictionary,
	grid_mgr: GridManager,
	highlights: Node2D
) -> void:
	_cell_size = cell_size
	_module_script_by_id = module_scripts
	grid_manager = grid_mgr
	highlights_root = highlights


func set_enabled(enabled: bool) -> void:
	_is_enabled = enabled
	if not enabled:
		cancel_build_mode()


func is_build_mode_active() -> bool:
	return _active_build_type != ""


func get_active_build_type() -> String:
	return _active_build_type


func get_active_build_size() -> Vector2i:
	return _active_build_size


func handle_pointer_input(pointer_pos: Vector2, grid_origin: Vector2) -> bool:
	if not _is_enabled:
		return false
	if _active_build_type == "":
		return false
	
	var grid_pos: Vector2i = _world_to_grid(pointer_pos, grid_origin)
	
	if grid_manager.canBuildAt(grid_pos, _active_build_type, _active_build_size):
		build_executed.emit(_active_build_type, grid_pos, true)
		_clear_highlights()
		return true
	else:
		# Клик внутри сетки, но мимо подсветки — отмена
		if _is_inside_grid(grid_pos):
			var cancelled_type: String = _active_build_type
			_clear_highlights()
			GameEvents.build_mode_cancelled.emit(cancelled_type)
		return false


func enter_build_mode(module_type: String) -> void:
	if not _is_enabled:
		return
	if not _module_script_by_id.has(module_type):
		return
	
	_clear_highlights()
	_active_build_type = module_type
	
	var script_ref: Script = _module_script_by_id[module_type]
	var temp_module: ModuleBase = script_ref.new() as ModuleBase
	_active_build_size = temp_module.grid_size
	temp_module.queue_free()
	
	_show_valid_placements(module_type, _active_build_size)


func cancel_build_mode() -> void:
	if _active_build_type != "":
		var cancelled_type: String = _active_build_type
		_clear_highlights()
		GameEvents.build_mode_cancelled.emit(cancelled_type)


func _on_build_requested(module_type: String, requested_position: Vector2) -> void:
	if not _is_enabled:
		return
	if not _module_script_by_id.has(module_type):
		return
	
	if requested_position == Vector2.ZERO:
		enter_build_mode(module_type)


func _clear_highlights() -> void:
	if highlights_root != null:
		for child in highlights_root.get_children():
			child.queue_free()
	_active_build_type = ""


func _show_valid_placements(type: String, size: Vector2i) -> void:
	if grid_manager == null or highlights_root == null:
		return
	
	var count: int = 0
	for y in range(GridManager.GRID_HEIGHT):
		for x in range(GridManager.GRID_WIDTH):
			var pos: Vector2i = Vector2i(x, y)
			if grid_manager.canBuildAt(pos, type, size):
				_create_highlight(pos, size)
				count += 1
	print("BuildModeController: Found ", count, " valid placements for ", type)


func _create_highlight(pos: Vector2i, size: Vector2i) -> void:
	var rect: ColorRect = ColorRect.new()
	rect.color = Color(0.5, 0.5, 0.5, 0.4)
	rect.size = Vector2(size.x * _cell_size - 4, size.y * _cell_size - 4)
	rect.position = Vector2(pos.x * _cell_size + 2, pos.y * _cell_size + 2)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlights_root.add_child(rect)


func _world_to_grid(world_position: Vector2, grid_origin: Vector2) -> Vector2i:
	var local_position: Vector2 = world_position - grid_origin
	return Vector2i(
		int(floor(local_position.x / _cell_size)),
		int(floor(local_position.y / _cell_size))
	)


func _is_inside_grid(grid_pos: Vector2i) -> bool:
	return (
		grid_pos.x >= 0 and grid_pos.x < GridManager.GRID_WIDTH and
		grid_pos.y >= 0 and grid_pos.y < GridManager.GRID_HEIGHT
	)
