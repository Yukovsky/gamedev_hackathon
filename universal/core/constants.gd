extends Node
## Глобальные константы и ID для проекта

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
}

# ========== Путь к единому конфигу баланса ==========
const RESOURCE_BALANCE_PATH: String = "res://data/room_stats/resource_balance.tres"

# ========== Кэш загруженных конфигов ==========
var MODULE_COST_METAL: Dictionary = {}
var _resource_initial_metal: int = 0
var _resource_max_metal: int = 0
var _resource_hull_bonus: int = 0
var _is_balance_loaded: bool = false

# Стоимости из БАЛАНС.csv по номеру итерации (0..9), дальше используется последний индекс.
const ITERATION_MODULE_COSTS: Dictionary = {
	MODULE_REACTOR: [350, 525, 788, 1182, 1772, 2658, 3987, 5981, 8971, 13456],
	MODULE_HULL: [75, 98, 127, 165, 215, 279, 363, 471, 612, 796],
	MODULE_COLLECTOR: [100, 130, 169, 220, 286, 372, 483, 628, 816, 1061],
	MODULE_TURRET: [240, 312, 406, 528, 686, 892, 1159, 1506, 1958, 2546],
}

# ========== Параметры ядра ==========
const BASE_METAL_PER_CLICK: int = 10
const BASE_ENERGY_PER_CLICK: int = 5
const CORE_BASE_DEFENCE: int = 10
const CORE_RADIUS_CELLS: int = 1

# ========== Улучшения ==========
const UPGRADE_CORE_ID: String = "core_upgrade"
const UPGRADE_CORE_NAME: String = "Улучшение ядра"

# Таблица из БАЛАНС (2).csv по уровням улучшения ядра.
const CORE_UPGRADE_REWARD_TABLE: Array[Dictionary] = [
	{DEBRIS_TRASH_1: 17, DEBRIS_TRASH_2: 13, DEBRIS_TRASH_3: 20},
	{DEBRIS_TRASH_1: 21, DEBRIS_TRASH_2: 16, DEBRIS_TRASH_3: 25},
	{DEBRIS_TRASH_1: 27, DEBRIS_TRASH_2: 20, DEBRIS_TRASH_3: 31},
	{DEBRIS_TRASH_1: 33, DEBRIS_TRASH_2: 25, DEBRIS_TRASH_3: 39},
	{DEBRIS_TRASH_1: 42, DEBRIS_TRASH_2: 32, DEBRIS_TRASH_3: 49},
	{DEBRIS_TRASH_1: 52, DEBRIS_TRASH_2: 61, DEBRIS_TRASH_3: 70},#А здесь точно 70 не надо???
]

# Стоимость перехода на следующий уровень (0->1, 1->2, ...).
const CORE_UPGRADE_COSTS: Array[int] = [375, 469, 586, 733, 916]

const UPGRADE_IDS: Array[String] = [UPGRADE_CORE_ID]

# ========== UI Слои ==========
const UI_LAYER_HUD: int = 0
const UI_LAYER_MENU: int = 1
const UI_LAYER_POPUP: int = 2


func _ready() -> void:
	_load_balance_config()


func _ensure_balance_loaded() -> void:
	if _is_balance_loaded:
		return
	_load_balance_config()


func get_module_cost(module_id: String) -> int:
	_ensure_balance_loaded()
	if module_id == MODULE_TURRET:
		return int(MODULE_COST_METAL.get(MODULE_TURRET, MODULE_TURRET_DEFAULT_COST))
	return int(MODULE_COST_METAL.get(module_id, 0))


func get_module_cost_for_iteration(module_id: String, iteration: int) -> int:
	_ensure_balance_loaded()
	if ITERATION_MODULE_COSTS.has(module_id):
		var iteration_costs: Array = ITERATION_MODULE_COSTS[module_id]
		if iteration_costs.is_empty():
			return get_module_cost(module_id)
		var index: int = clamp(iteration, 0, iteration_costs.size() - 1)
		return int(iteration_costs[index])
	return get_module_cost(module_id)


func is_incremental_price_module(module_id: String) -> bool:
	return ITERATION_MODULE_COSTS.has(module_id)


func get_resource_initial_metal() -> int:
	_ensure_balance_loaded()
	return _resource_initial_metal


func get_resource_max_metal() -> int:
	_ensure_balance_loaded()
	return _resource_max_metal


func get_hull_metal_bonus() -> int:
	_ensure_balance_loaded()
	return _resource_hull_bonus


func get_core_upgrade_max_level() -> int:
	if CORE_UPGRADE_REWARD_TABLE.is_empty():
		return 0
	return CORE_UPGRADE_REWARD_TABLE.size() - 1


func get_core_upgrade_next_cost(current_level: int) -> int:
	if current_level < 0:
		return CORE_UPGRADE_COSTS[0]
	if current_level >= CORE_UPGRADE_COSTS.size():
		return -1
	return CORE_UPGRADE_COSTS[current_level]


func get_core_upgrade_reward(debris_type: int, level: int) -> int:
	if CORE_UPGRADE_REWARD_TABLE.is_empty():
		return 0

	var clamped_level: int = clamp(level, 0, CORE_UPGRADE_REWARD_TABLE.size() - 1)
	var reward_row: Dictionary = CORE_UPGRADE_REWARD_TABLE[clamped_level]
	return int(reward_row.get(debris_type, 0))


func _load_balance_config() -> void:
	var loaded: Resource = load(RESOURCE_BALANCE_PATH)
	if loaded is ResourceBalanceConfig:
		var config: ResourceBalanceConfig = loaded as ResourceBalanceConfig
		MODULE_COST_METAL = {
			MODULE_COLLECTOR: max(0, config.collector_cost_metal),
			MODULE_REACTOR: max(0, config.reactor_cost_metal),

			MODULE_HULL: max(0, config.hull_cost_metal),
			MODULE_TURRET: MODULE_TURRET_DEFAULT_COST,
		}
		_resource_initial_metal = max(0, config.initial_metal)
		_resource_max_metal = max(1, config.max_metal)
		_resource_hull_bonus = max(0, config.hull_metal_bonus)
		_is_balance_loaded = true
