extends Node
## Глобальные константы и ID для проекта

# ========== Типы модулей ==========
enum ModuleType {
	CORE = 0,
	COLLECTOR = 1,
	REACTOR = 2,
	STORAGE = 3,
	DEFENSE = 4,
	TURRET = 5,
}

# Строковые ID модулей для более удобного использования
const MODULE_CORE: String = "core"
const MODULE_COLLECTOR: String = "collector"
const MODULE_REACTOR: String = "reactor"
const MODULE_STORAGE: String = "storage"
const MODULE_DEFENSE: String = "defense"
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
	"storage": MODULE_STORAGE,
	"defense": MODULE_DEFENSE,
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
	MODULE_REACTOR: [350.0, 525.0, 787.5, 1181.25, 1771.875, 2657.8125, 3986.71875, 5980.078125, 8970.117188, 13455.17578],
	MODULE_HULL: [75.0, 97.5, 126.75, 164.775, 214.2075, 278.46975, 362.010675, 470.6138775, 611.7980408, 795.337453],
	MODULE_COLLECTOR: [100.0, 130.0, 169.0, 219.7, 285.61, 371.293, 482.6809, 627.48517, 815.730721, 1060.449937],
	MODULE_TURRET: [240.0, 312.0, 405.6, 527.28, 685.464, 891.1032, 1158.43416, 1505.964408, 1957.75373, 2545.07985],
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
	{DEBRIS_TRASH_1: 17.0, DEBRIS_TRASH_2: 13.0, DEBRIS_TRASH_3: 20.0},
	{DEBRIS_TRASH_1: 21.25, DEBRIS_TRASH_2: 16.25, DEBRIS_TRASH_3: 25.0},
	{DEBRIS_TRASH_1: 26.5625, DEBRIS_TRASH_2: 20.3125, DEBRIS_TRASH_3: 31.25},
	{DEBRIS_TRASH_1: 33.203125, DEBRIS_TRASH_2: 25.390625, DEBRIS_TRASH_3: 39.0625},
	{DEBRIS_TRASH_1: 41.50390625, DEBRIS_TRASH_2: 31.73828125, DEBRIS_TRASH_3: 48.828125},
]

# Стоимость перехода на следующий уровень (0->1, 1->2, ...).
const CORE_UPGRADE_COSTS: Array[float] = [375.0, 468.75, 585.9375, 732.421875]

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
		return int(ceil(float(iteration_costs[index])))
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
		return int(ceil(CORE_UPGRADE_COSTS[0]))
	if current_level >= CORE_UPGRADE_COSTS.size():
		return -1
	return int(ceil(CORE_UPGRADE_COSTS[current_level]))


func get_core_upgrade_reward(debris_type: int, level: int) -> int:
	if CORE_UPGRADE_REWARD_TABLE.is_empty():
		return 0

	var clamped_level: int = clamp(level, 0, CORE_UPGRADE_REWARD_TABLE.size() - 1)
	var reward_row: Dictionary = CORE_UPGRADE_REWARD_TABLE[clamped_level]
	var raw_reward: float = float(reward_row.get(debris_type, 0.0))
	return int(round(raw_reward))


func _load_balance_config() -> void:
	var loaded: Resource = load(RESOURCE_BALANCE_PATH)
	if loaded is ResourceBalanceConfig:
		var config: ResourceBalanceConfig = loaded as ResourceBalanceConfig
		MODULE_COST_METAL = {
			MODULE_COLLECTOR: max(0, config.collector_cost_metal),
			MODULE_REACTOR: max(0, config.reactor_cost_metal),
			MODULE_STORAGE: max(0, config.storage_cost_metal),
			MODULE_DEFENSE: max(0, config.defense_cost_metal),
			MODULE_HULL: max(0, config.hull_cost_metal),
			MODULE_TURRET: MODULE_TURRET_DEFAULT_COST,
		}
		_resource_initial_metal = max(0, config.initial_metal)
		_resource_max_metal = max(1, config.max_metal)
		_resource_hull_bonus = max(0, config.hull_metal_bonus)
		_is_balance_loaded = true
