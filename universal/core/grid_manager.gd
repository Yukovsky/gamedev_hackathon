extends Node
class_name GridManager

const GRID_WIDTH: int = 12
const GRID_HEIGHT: int = 20
const CELL_SIZE: int = 90

var _occupied_cells: Dictionary = {}
var _powered_cells: Dictionary = {}
var _reactor_cells: Array[Vector2i] = []
var _core_cells: Array[Vector2i] = []

func reset_grid() -> void:
	_occupied_cells.clear()
	_powered_cells.clear()
	_reactor_cells.clear()
	_core_cells.clear()

func canBuildAt(pos: Vector2i, module_type: String, size: Vector2i = Vector2i.ONE) -> bool:
	if not _is_area_inside_grid(pos, size):
		return false

	if _is_area_occupied(pos, size):
		return false

	# ХОТЯ БЫ ОДНА клетка под модулем должна быть запитана
	if not _is_any_cell_powered(pos, size):
		return false

	# НОВОЕ ПРАВИЛО: Реактор нельзя ставить вплотную к ядру или другому реактору
	# Используем строковую константу напрямую для надежности
	if module_type == "reactor":
		if _is_adjacent_to_any(pos, size, _core_cells):
			print("GridManager: Cannot place Reactor adjacent to Core!")
			return false
		if _is_adjacent_to_any(pos, size, _reactor_cells):
			print("GridManager: Cannot place Reactor adjacent to another Reactor!")
			return false

	return true

func register_core(pos: Vector2i, size: Vector2i, entity: Node) -> void:
	var core_cells: Array[Vector2i] = _collect_cells(pos, size)
	for cell in core_cells:
		_occupied_cells[cell] = entity
		if not _core_cells.has(cell):
			_core_cells.append(cell)
	_mark_power_around_cells(core_cells, 1)

func register_module(pos: Vector2i, size: Vector2i, module_type: String, entity: Node) -> void:
	var module_cells: Array[Vector2i] = _collect_cells(pos, size)
	for cell in module_cells:
		_occupied_cells[cell] = entity

	if module_type == "reactor":
		for cell in module_cells:
			if not _reactor_cells.has(cell):
				_reactor_cells.append(cell)
		_mark_power_around_cells(module_cells, 1)

func unregister_module(entity: Node) -> void:
	var keys_to_remove: Array[Vector2i] = []
	for key in _occupied_cells.keys():
		if _occupied_cells[key] == entity:
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		_occupied_cells.erase(key)
		_reactor_cells.erase(key)
		_core_cells.erase(key)

func get_occupied_cells() -> Dictionary:
	return _occupied_cells.duplicate(true)

func _is_area_inside_grid(pos: Vector2i, size: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and (pos.x + size.x) <= GRID_WIDTH and (pos.y + size.y) <= GRID_HEIGHT

func _is_area_occupied(pos: Vector2i, size: Vector2i) -> bool:
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			if _occupied_cells.has(Vector2i(x, y)): return true
	return false

func _is_any_cell_powered(pos: Vector2i, size: Vector2i) -> bool:
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			if _powered_cells.has(Vector2i(x, y)): return true
	return false

func _is_adjacent_to_any(pos: Vector2i, size: Vector2i, target_list: Array[Vector2i]) -> bool:
	if target_list.is_empty(): return false
	# Проверяем все клетки вокруг области постройки (включая диагонали)
	for x in range(pos.x - 1, pos.x + size.x + 1):
		for y in range(pos.y - 1, pos.y + size.y + 1):
			if target_list.has(Vector2i(x, y)):
				return true
	return false

func _mark_power_around_cells(cells: Array[Vector2i], radius: int) -> void:
	for source_cell in cells:
		for x in range(source_cell.x - radius, source_cell.x + radius + 1):
			for y in range(source_cell.y - radius, source_cell.y + radius + 1):
				var cell: Vector2i = Vector2i(x, y)
				if cell.x >= 0 and cell.y >= 0 and cell.x < GRID_WIDTH and cell.y < GRID_HEIGHT:
					_powered_cells[cell] = true

func _collect_cells(pos: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			cells.append(Vector2i(x, y))
	return cells
