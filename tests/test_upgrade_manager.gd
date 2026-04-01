extends "res://addons/gut/test.gd"

var upgrade_manager
var resource_manager

func before_each():
	upgrade_manager = UpgradeManager
	resource_manager = ResourceManager
	upgrade_manager.reset_run_state()
	resource_manager.reset_run_state()

func test_initial_levels():
	assert_eq(upgrade_manager.get_upgrade_level(Constants.UPGRADE_CORE_ID), 0, "Начальный уровень ядра должен быть 0")

func test_upgrade_cost():
	var level = upgrade_manager.get_upgrade_level(Constants.UPGRADE_CORE_ID)
	var expected_cost = Constants.get_core_upgrade_next_cost(level)
	assert_eq(upgrade_manager.get_upgrade_next_cost(Constants.UPGRADE_CORE_ID), expected_cost, "Стоимость должна соответствовать уровню")

func test_can_purchase():
	var cost = upgrade_manager.get_upgrade_next_cost(Constants.UPGRADE_CORE_ID)
	
	resource_manager.metal = cost - 1
	assert_false(upgrade_manager.can_purchase(Constants.UPGRADE_CORE_ID), "Нельзя купить, если металла не хватает")
	
	resource_manager.metal = cost
	assert_true(upgrade_manager.can_purchase(Constants.UPGRADE_CORE_ID), "Можно купить, если металла ровно столько, сколько нужно")

func test_purchase_process():
	var cost = upgrade_manager.get_upgrade_next_cost(Constants.UPGRADE_CORE_ID)
	resource_manager.metal = cost + 50
	
	var success = upgrade_manager.purchase(Constants.UPGRADE_CORE_ID)
	
	assert_true(success, "Покупка должна быть успешной")
	assert_eq(upgrade_manager.get_upgrade_level(Constants.UPGRADE_CORE_ID), 1, "Уровень должен повыситься до 1")
	assert_eq(resource_manager.metal, 50, "Металл должен списаться корректно")

func test_max_level():
	var max_lv = upgrade_manager.get_upgrade_max_level(Constants.UPGRADE_CORE_ID)
	
	# Искусственно ставим максимальный уровень
	var levels = {Constants.UPGRADE_CORE_ID: max_lv}
	upgrade_manager.set_upgrade_levels(levels)
	
	assert_true(upgrade_manager.is_upgrade_maxed(Constants.UPGRADE_CORE_ID), "Апгрейд должен считаться максимальным")
	assert_false(upgrade_manager.purchase(Constants.UPGRADE_CORE_ID), "Нельзя купить апгрейд выше максимального уровня")
