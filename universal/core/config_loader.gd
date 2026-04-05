extends Node
## Загрузчик конфигурационных файлов баланса.
## Отвечает за ленивую загрузку и кэширование .tres ресурсов.
## Используется как Autoload (ConfigLoader).
## ВАЖНО: Не добавлять class_name — конфликтует с именем autoload синглтона.

# Пути к конфигам
const RESOURCE_BALANCE_PATH: String = "res://data/room_stats/resource_balance.tres"
const MODULE_PRICING_PATH: String = "res://data/module_pricing.tres"
const CORE_UPGRADE_PATH: String = "res://data/core_upgrade.tres"

# Кэш загруженных конфигов
var _resource_balance: ResourceBalanceConfig
var _pricing_config: ModulePricingConfig
var _core_upgrade_config: CoreUpgradeConfig

# Кэшированные значения из resource_balance
var _module_cost_metal: Dictionary = {}
var _resource_initial_metal: int = 0
var _resource_max_metal: int = 50
var _resource_hull_bonus: int = 0
var _is_balance_loaded: bool = false


func _ready() -> void:
	_load_balance_config()


# ========== Resource Balance ==========

func get_module_cost(module_id: String) -> int:
	_ensure_balance_loaded()
	if module_id == Constants.MODULE_TURRET:
		return int(_module_cost_metal.get(Constants.MODULE_TURRET, Constants.MODULE_TURRET_DEFAULT_COST))
	if module_id == Constants.MODULE_REPAIR:
		return 5
	return int(_module_cost_metal.get(module_id, 0))


func get_resource_initial_metal() -> int:
	_ensure_balance_loaded()
	return _resource_initial_metal


func get_resource_max_metal() -> int:
	_ensure_balance_loaded()
	return _resource_max_metal


func get_hull_metal_bonus() -> int:
	_ensure_balance_loaded()
	return _resource_hull_bonus


func _ensure_balance_loaded() -> void:
	if _is_balance_loaded:
		return
	_load_balance_config()


func _load_balance_config() -> void:
	var loaded: Resource = load(RESOURCE_BALANCE_PATH)
	if loaded is ResourceBalanceConfig:
		_resource_balance = loaded as ResourceBalanceConfig
		_module_cost_metal = {
			Constants.MODULE_COLLECTOR: max(0, _resource_balance.collector_cost_metal),
			Constants.MODULE_REACTOR: max(0, _resource_balance.reactor_cost_metal),
			Constants.MODULE_HULL: max(0, _resource_balance.hull_cost_metal),
			Constants.MODULE_TURRET: Constants.MODULE_TURRET_DEFAULT_COST,
		}
		_resource_initial_metal = max(0, _resource_balance.initial_metal)
		_resource_max_metal = max(1, _resource_balance.max_metal)
		_resource_hull_bonus = max(0, _resource_balance.hull_metal_bonus)
		_is_balance_loaded = true


# ========== Module Pricing ==========

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


func _ensure_pricing_loaded() -> void:
	if _pricing_config != null:
		return
	var loaded: Resource = load(MODULE_PRICING_PATH)
	if loaded is ModulePricingConfig:
		_pricing_config = loaded as ModulePricingConfig


# ========== Core Upgrade ==========

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


func _ensure_core_upgrade_loaded() -> void:
	if _core_upgrade_config != null:
		return
	var loaded: Resource = load(CORE_UPGRADE_PATH)
	if loaded is CoreUpgradeConfig:
		_core_upgrade_config = loaded as CoreUpgradeConfig
