extends Node
## Глобальные константы и ID для проекта.
## ТОЛЬКО константы и enum'ы. Загрузка конфигов — в ConfigLoader.

# ========== Типы модулей ==========
enum ModuleType {
	CORE = 0,
	COLLECTOR = 1,
	REACTOR = 2,
	TURRET = 3,
}

# Строковые ID модулей для более удобного использования
const MODULE_CORE: String = "core"
const MODULE_COLLECTOR: String = "collector"
const MODULE_REACTOR: String = "reactor"
const MODULE_HULL: String = "hull"
const MODULE_TURRET: String = "turret"
const MODULE_REPAIR: String = "repair"
const MODULE_TURRET_DEFAULT_COST: int = 240

# ========== Типы мусора ==========
const DEBRIS_TRASH_1: int = 0
const DEBRIS_TRASH_2: int = 1
const DEBRIS_TRASH_3: int = 2

const MODULE_IDS = {
	"core": MODULE_CORE,
	"collector": MODULE_COLLECTOR,
	"reactor": MODULE_REACTOR,
	"hull": MODULE_HULL,
	"turret": MODULE_TURRET,
	"repair": MODULE_REPAIR,
}

# ========== Параметры ядра ==========
const BASE_METAL_PER_CLICK: int = 10
const BASE_ENERGY_PER_CLICK: int = 5
const CORE_BASE_DEFENCE: int = 10
const CORE_RADIUS_CELLS: int = 1

# ========== Улучшения ==========
const UPGRADE_CORE_ID: String = "core_upgrade"
const UPGRADE_CORE_NAME: String = "Улучшение ядра"
const UPGRADE_IDS: Array[String] = [UPGRADE_CORE_ID]

# ========== UI Слои ==========
const UI_LAYER_HUD: int = 0
const UI_LAYER_MENU: int = 1
const UI_LAYER_POPUP: int = 2


# ========== Делегирование в ConfigLoader ==========
# Эти методы сохранены для обратной совместимости.
# Фактическая загрузка происходит в ConfigLoader Autoload.

func get_module_cost(module_id: String) -> int:
	return ConfigLoader.get_module_cost(module_id)


func get_module_cost_for_iteration(module_id: String, iteration: int) -> int:
	return ConfigLoader.get_module_cost_for_iteration(module_id, iteration)


func is_incremental_price_module(module_id: String) -> bool:
	return ConfigLoader.is_incremental_price_module(module_id)


func get_resource_initial_metal() -> int:
	return ConfigLoader.get_resource_initial_metal()


func get_resource_max_metal() -> int:
	return ConfigLoader.get_resource_max_metal()


func get_hull_metal_bonus() -> int:
	return ConfigLoader.get_hull_metal_bonus()


func get_core_upgrade_max_level() -> int:
	return ConfigLoader.get_core_upgrade_max_level()


func get_core_upgrade_next_cost(current_level: int) -> int:
	return ConfigLoader.get_core_upgrade_next_cost(current_level)


func get_core_upgrade_reward(debris_type: int, level: int) -> int:
	return ConfigLoader.get_core_upgrade_reward(debris_type, level)
