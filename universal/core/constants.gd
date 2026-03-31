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

# ========== Пути к конфигам баланса ==========
const RESOURCE_BALANCE_PATH: String = "res://data/room_stats/resource_balance.tres"
const MODULE_PRICING_PATH: String = "res://data/module_pricing.tres"
const CORE_UPGRADE_PATH: String = "res://data/core_upgrade.tres"

# ========== Кэш загруженных конфигов ==========
var MODULE_COST_METAL: Dictionary = {}
var _resource_initial_metal: int = 0
var _resource_max_metal: int = 0
var _resource_hull_bonus: int = 0
var _is_balance_loaded: bool = false
var _pricing_config: ModulePricingConfig = null
var _core_upgrade_config: CoreUpgradeConfig = null

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


func _ready() -> void:
	_load_balance_config()


func _ensure_balance_loaded() -> void:
	if _is_balance_loaded:
		return
	_load_balance_config()


func _ensure_pricing_loaded() -> void:
	if _pricing_config != null:
		return
	var loaded: Resource = load(MODULE_PRICING_PATH)
	if loaded is ModulePricingConfig:
		_pricing_config = loaded as ModulePricingConfig


func _ensure_core_upgrade_loaded() -> void:
	if _core_upgrade_config != null:
		return
	var loaded: Resource = load(CORE_UPGRADE_PATH)
	if loaded is CoreUpgradeConfig:
		_core_upgrade_config = loaded as CoreUpgradeConfig


func get_module_cost(module_id: String) -> int:
	_ensure_balance_loaded()
	if module_id == MODULE_TURRET:
		return int(MODULE_COST_METAL.get(MODULE_TURRET, MODULE_TURRET_DEFAULT_COST))
	return int(MODULE_COST_METAL.get(module_id, 0))


func get_module_cost_for_iteration(module_id: String, iteration: int) -> int:
	_ensure_balance_loaded()
	_ensure_pricing_loaded()
	
	if _pricing_config != null and _pricing_config.has_incremental_pricing(module_id):
		return _pricing_config.get_cost_for_module(module_id, iteration)
	
	return get_module_cost(module_id)


func is_incremental_price_module(module_id: String) -> bool:
	_ensure_pricing_loaded()
	if _pricing_config != null:
		return _pricing_config.has_incremental_pricing(module_id)
	return false


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
	_ensure_core_upgrade_loaded()
	if _core_upgrade_config != null:
		return _core_upgrade_config.get_max_level()
	return 0


func get_core_upgrade_next_cost(current_level: int) -> int:
	_ensure_core_upgrade_loaded()
	if _core_upgrade_config != null:
		return _core_upgrade_config.get_upgrade_cost(current_level)
	return -1


func get_core_upgrade_reward(debris_type: int, level: int) -> int:
	_ensure_core_upgrade_loaded()
	if _core_upgrade_config != null:
		return _core_upgrade_config.get_reward_for_debris(debris_type, level)
	return 0


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
