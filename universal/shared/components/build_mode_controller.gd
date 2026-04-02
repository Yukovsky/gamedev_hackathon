extends Node
class_name BuildModeController
## Контроллер режима постройки модулей.
## Управляет подсветкой допустимых позиций, обработкой клика и размещением.

signal build_executed(module_type: String, grid_pos: Vector2i, success: bool)

@export var highlights_root: Node2D
@export var grid_manager: GridManager
@export var border_thickness: int = 3
@export var corner_radius: int = 6
@export var border_color: Color = Color.YELLOW
@export var fill_color: Color = Color(0.5, 0.5, 0.5, 0.4)

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
	GameEvents.build_mode_changed.emit(true)
	
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
	if _active_build_type != "":
		GameEvents.build_mode_changed.emit(false)
	_active_build_type = ""


func _show_valid_placements(type: String, size: Vector2i) -> void:
	if grid_manager == null or highlights_root == null:
		return

	var occupied_cells: Dictionary = {}
	
	for y in range(GridManager.GRID_HEIGHT):
		for x in range(GridManager.GRID_WIDTH):
			var pos: Vector2i = Vector2i(x, y)
			if grid_manager.canBuildAt(pos, type, size):
				_add_highlight_area(occupied_cells, pos, size)

	for cell_pos: Vector2i in occupied_cells.keys():
		_create_highlight_cell(cell_pos, occupied_cells)


func _add_highlight_area(occupied_cells: Dictionary, pos: Vector2i, size: Vector2i) -> void:
	for offset_y in range(size.y):
		for offset_x in range(size.x):
			occupied_cells[Vector2i(pos.x + offset_x, pos.y + offset_y)] = true


func _create_highlight_cell(pos: Vector2i, occupied_cells: Dictionary) -> void:
	var panel: Panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(pos.x * _cell_size, pos.y * _cell_size)
	panel.size = Vector2(_cell_size, _cell_size)
	panel.add_theme_stylebox_override("panel", _build_highlight_style(pos, occupied_cells))
	highlights_root.add_child(panel)


func _build_highlight_style(pos: Vector2i, occupied_cells: Dictionary) -> StyleBoxFlat:
	var has_left: bool = occupied_cells.has(pos + Vector2i(-1, 0))
	var has_right: bool = occupied_cells.has(pos + Vector2i(1, 0))
	var has_up: bool = occupied_cells.has(pos + Vector2i(0, -1))
	var has_down: bool = occupied_cells.has(pos + Vector2i(0, 1))
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = 0 if has_left else border_thickness
	style.border_width_top = 0 if has_up else border_thickness
	style.border_width_right = border_thickness
	style.border_width_bottom = border_thickness
	style.corner_radius_top_left = corner_radius if not has_up and not has_left else 0
	style.corner_radius_top_right = corner_radius if not has_up and not has_right else 0
	style.corner_radius_bottom_left = corner_radius if not has_down and not has_left else 0
	style.corner_radius_bottom_right = corner_radius if not has_down and not has_right else 0
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.0
	return style


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
