extends "res://addons/gut/test.gd"

var grid_manager

func before_each():
	grid_manager = GridManager.new()
	grid_manager.reset_grid()

func after_each():
	grid_manager.free()

func test_grid_boundaries():
	assert_false(grid_manager._is_area_inside_grid(Vector2i(-1, 0), Vector2i.ONE))
	assert_false(grid_manager._is_area_inside_grid(Vector2i(12, 0), Vector2i.ONE))
	assert_true(grid_manager._is_area_inside_grid(Vector2i(0, 0), Vector2i.ONE))
	assert_true(grid_manager._is_area_inside_grid(Vector2i(11, 19), Vector2i.ONE))

func test_core_registration_and_power():
	var core_pos = Vector2i(5, 5)
	var core_size = Vector2i(2, 2)
	var node = Node.new()
	grid_manager.register_core(core_pos, core_size, node)
	
	assert_true(grid_manager._is_area_occupied(core_pos, core_size))
	assert_true(grid_manager._is_any_cell_powered(core_pos + Vector2i(1, 1), Vector2i.ONE))
	
	node.free()

func test_adjacency_rule():
	var core_pos = Vector2i(5, 5)
	var node = Node.new()
	grid_manager.register_core(core_pos, Vector2i(1, 1), node)
	
	assert_true(grid_manager._is_cardinally_adjacent_to_occupied(core_pos + Vector2i(1, 0), Vector2i.ONE))
	assert_false(grid_manager._is_cardinally_adjacent_to_occupied(core_pos + Vector2i(1, 1), Vector2i.ONE))
	
	node.free()

func test_can_build_at_logic():
	var core_pos = Vector2i(5, 5)
	var core_node = Node.new()
	grid_manager.register_core(core_pos, Vector2i(1, 1), core_node)
	
	# Постройка корпуса рядом с ядром (можно)
	var hull_pos = core_pos + Vector2i(1, 0)
	assert_true(grid_manager.canBuildAt(hull_pos, Constants.MODULE_HULL), "Корпус можно строить рядом с ядром")
	
	# Регистрируем корпус
	var hull_node = Node.new()
	grid_manager.register_module(hull_pos, Vector2i.ONE, Constants.MODULE_HULL, hull_node)
	
	# Постройка реактора подальше от ядра (чтобы не накрывал его зоной), но рядом с корпусом
	# Радиус ядра обычно 2-3 клетки. Попробуем поставить реактор на расстоянии 3 клетки от ядра.
	var reactor_pos = core_pos + Vector2i(4, 0) # Слишком далеко, нет смежности
	# Ставим цепочку корпусов
	grid_manager.register_module(core_pos + Vector2i(2, 0), Vector2i.ONE, Constants.MODULE_HULL, Node.new())
	grid_manager.register_module(core_pos + Vector2i(3, 0), Vector2i.ONE, Constants.MODULE_HULL, Node.new())
	
	var safe_reactor_pos = core_pos + Vector2i(4, 0)
	# Теперь он смежен с последним корпусом и достаточно далеко от ядра
	assert_true(grid_manager.canBuildAt(safe_reactor_pos, Constants.MODULE_REACTOR), "Реактор можно строить на безопасном расстоянии от ядра")
	
	# Очистка созданных нод (в реальном тесте лучше использовать autofree)
	core_node.free()
	hull_node.free()
	for cell in grid_manager.get_occupied_cells().values():
		if is_instance_valid(cell): cell.free()

func test_height_limit():
	var core_pos = Vector2i(5, 5)
	var node = Node.new()
	grid_manager.register_core(core_pos, Vector2i(1, 1), node)
	
	assert_false(grid_manager.canBuildAt(core_pos + Vector2i(0, 1), Constants.MODULE_HULL), "Ниже ядра нельзя")
	assert_true(grid_manager.canBuildAt(core_pos + Vector2i(1, 0), Constants.MODULE_HULL), "На уровне можно")
	
	node.free()

func test_unregister_module():
	var pos = Vector2i(2, 2)
	var entity = Node.new()
	grid_manager.register_module(pos, Vector2i.ONE, Constants.MODULE_HULL, entity)
	grid_manager.unregister_module(entity)
	assert_false(grid_manager._is_area_occupied(pos, Vector2i.ONE))
	entity.free()
