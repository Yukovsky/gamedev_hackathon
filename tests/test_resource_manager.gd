extends "res://addons/gut/test.gd"

var resource_manager

func before_each():
	# Мы тестируем синглтон, поэтому сбрасываем его состояние перед каждым тестом
	# Хотя в реальном Godot ResourceManager - это Autoload, в GUT мы можем 
	# обращаться к нему напрямую, если он подгружен.
	resource_manager = ResourceManager
	resource_manager.reset_run_state()

func test_initial_metal():
	assert_eq(resource_manager.metal, Constants.get_resource_initial_metal(), "Начальный металл должен совпадать с константами")

func test_add_metal():
	resource_manager.metal = 50
	resource_manager.add_metal(10)
	assert_eq(resource_manager.metal, 60, "Металл должен увеличиться на 10")

func test_max_metal_limit():
	resource_manager.add_metal(resource_manager.max_metal + 100)
	assert_eq(resource_manager.metal, resource_manager.max_metal, "Металл не должен превышать лимит max_metal")

func test_spend_metal_success():
	resource_manager.metal = 100
	var success = resource_manager.spend_metal(40)
	assert_true(success, "Должна быть возможность потратить металл при достаточном балансе")
	assert_eq(resource_manager.metal, 60, "Запас металла должен уменьшиться на 40")

func test_spend_metal_fail():
	resource_manager.metal = 30
	var success = resource_manager.spend_metal(40)
	assert_false(success, "Нельзя потратить больше, чем есть на балансе")
	assert_eq(resource_manager.metal, 30, "Запас металла не должен измениться при неудачной трате")

func test_hull_increases_max_metal():
	var initial_max = resource_manager.max_metal
	var bonus = Constants.get_hull_metal_bonus()
	
	# Эмулируем постройку модуля корпуса, которую слушает ResourceManager
	# Напрямую вызываем _on_module_built, чтобы не зависеть от сигналов в тесте, 
	# либо просто эмитим сигнал через GameEvents
	GameEvents.module_built.emit(Constants.MODULE_HULL, Vector2.ZERO)
	
	assert_eq(resource_manager.max_metal, initial_max + bonus, "Максимальный лимит металла должен увеличиться на бонус корпуса")
