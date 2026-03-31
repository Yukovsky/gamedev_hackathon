extends RefCounted
class_name ModuleCollapseHandler
## Обработчик коллапса (уничтожения) неприсоединённых модулей.
## Использует BFS для определения связности с ядром.


static func find_unattached_modules(
	placed_modules: Array[ModuleBase],
	core_module: ModuleBase,
	occupied_cells: Dictionary
) -> Array[ModuleBase]:
	if core_module == null or not is_instance_valid(core_module):
		return []
	
	if occupied_cells.is_empty():
		return []
	
	# BFS от ядра
	var visited_cells: Dictionary = {}
	var queue: Array[Vector2i] = []
	
	for core_cell in core_module.get_occupied_cells():
		if occupied_cells.has(core_cell):
			visited_cells[core_cell] = true
			queue.append(core_cell)
	
	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for dir in dirs:
			var n: Vector2i = cell + dir
			if visited_cells.has(n):
				continue
			if occupied_cells.has(n):
				visited_cells[n] = true
				queue.append(n)
	
	# Собираем модули, не связанные с ядром
	var unattached: Array[ModuleBase] = []
	for module in placed_modules:
		if not is_instance_valid(module):
			continue
		if module == core_module:
			continue
		
		var connected: bool = false
		for c in module.get_occupied_cells():
			if visited_cells.has(c):
				connected = true
				break
		
		if not connected:
			unattached.append(module)
	
	return unattached
