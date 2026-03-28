extends Node
class_name GridManager

const GRID_WIDTH: int = 12
const GRID_HEIGHT: int = 20
const CELL_SIZE: int = 90

var _occupied_cells: Dictionary = {}
var _powered_cells: Dictionary = {}
var _reactor_cells: Array[Vector2i] = []


func reset_grid() -> void:
	_occupied_cells.clear()
	_powered_cells.clear()
	_reactor_cells.clear()


func canBuildAt(pos: Vector2i, module_type: String, size: Vector2i = Vector2i.ONE) -> bool:
	if not _is_area_inside_grid(pos, size):
		return false

	if _is_area_occupied(pos, size):
		return false

	if not _is_area_powered(pos, size):
		return false

	if module_type == Constants.MODULE_REACTOR and _intersects_reactor_zone(pos):
		return false

	return true


func register_core(pos: Vector2i, size: Vector2i, entity: Node) -> void:
	var core_cells: Array[Vector2i] = _collect_cells(pos, size)
	for cell in core_cells:
		_occupied_cells[cell] = entity

	_mark_power_around_cells(core_cells, Constants.CORE_RADIUS_CELLS)


func register_module(pos: Vector2i, size: Vector2i, module_type: String, entity: Node) -> void:
	var module_cells: Array[Vector2i] = _collect_cells(pos, size)
	for cell in module_cells:
		_occupied_cells[cell] = entity

	if module_type == Constants.MODULE_REACTOR:
		for cell in module_cells:
			_reactor_cells.append(cell)
		_mark_power_around_cells(module_cells, 1)


func unregister_module(entity: Node) -> void:
	var keys_to_remove: Array[Vector2i] = []
	for key in _occupied_cells.keys():
		if _occupied_cells[key] == entity:
			keys_to_remove.append(key)

	for key in keys_to_remove:
		_occupied_cells.erase(key)


func get_occupied_cells() -> Dictionary:
	return _occupied_cells.duplicate(true)


func _is_area_inside_grid(pos: Vector2i, size: Vector2i) -> bool:
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			if x < 0 or y < 0 or x >= GRID_WIDTH or y >= GRID_HEIGHT:
				return false
	return true


func _is_area_occupied(pos: Vector2i, size: Vector2i) -> bool:
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			var cell: Vector2i = Vector2i(x, y)
			if _occupied_cells.has(cell):
				return true
	return false


func _is_area_powered(pos: Vector2i, size: Vector2i) -> bool:
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			var cell: Vector2i = Vector2i(x, y)
			if not _powered_cells.has(cell):
				return false
	return true


func _intersects_reactor_zone(pos: Vector2i) -> bool:
	for reactor_cell in _reactor_cells:
		if abs(reactor_cell.x - pos.x) <= 1 and abs(reactor_cell.y - pos.y) <= 1:
			return true
	return false


func _mark_power_around_cells(cells: Array[Vector2i], radius: int) -> void:
	for source_cell in cells:
		for x in range(source_cell.x - radius, source_cell.x + radius + 1):
			for y in range(source_cell.y - radius, source_cell.y + radius + 1):
				var cell: Vector2i = Vector2i(x, y)
				if _is_area_inside_grid(cell, Vector2i.ONE):
					_powered_cells[cell] = true


func _collect_cells(pos: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			cells.append(Vector2i(x, y))
	return cells
