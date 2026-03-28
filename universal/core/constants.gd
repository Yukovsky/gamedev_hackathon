extends Node
## Глобальные константы и ID для проекта

# ========== Типы модулей ==========
enum ModuleType {
	CORE = 0,
	COLLECTOR = 1,
	REACTOR = 2,
	STORAGE = 3,
	DEFENSE = 4,
}

# Строковые ID модулей для более удобного использования
const MODULE_CORE: String = "core"
const MODULE_COLLECTOR: String = "collector"
const MODULE_REACTOR: String = "reactor"
const MODULE_STORAGE: String = "storage"
const MODULE_DEFENSE: String = "defense"
const MODULE_HULL: String = "hull"

const MODULE_IDS = {
	"core": MODULE_CORE,
	"collector": MODULE_COLLECTOR,
	"reactor": MODULE_REACTOR,
	"storage": MODULE_STORAGE,
	"defense": MODULE_DEFENSE,
	"hull": MODULE_HULL,
}

# ========== Путь к единому конфигу баланса ==========
const RESOURCE_BALANCE_PATH: String = "res://data/room_stats/resource_balance.tres"

# ========== Кэш загруженных конфигов ==========
var MODULE_COST_METAL: Dictionary = {}
var _resource_initial_metal: int = 0
var _resource_max_metal: int = 0
var _resource_hull_bonus: int = 0
var _is_balance_loaded: bool = false

# ========== Параметры ядра ==========
const BASE_METAL_PER_CLICK: int = 10
const BASE_ENERGY_PER_CLICK: int = 5
const CORE_BASE_DEFENCE: int = 10
const CORE_RADIUS_CELLS: int = 1

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
	return int(MODULE_COST_METAL.get(module_id, 0))


func get_resource_initial_metal() -> int:
	_ensure_balance_loaded()
	return _resource_initial_metal


func get_resource_max_metal() -> int:
	_ensure_balance_loaded()
	return _resource_max_metal


func get_hull_metal_bonus() -> int:
	_ensure_balance_loaded()
	return _resource_hull_bonus


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
		}
		_resource_initial_metal = max(0, config.initial_metal)
		_resource_max_metal = max(1, config.max_metal)
		_resource_hull_bonus = max(0, config.hull_metal_bonus)
		_is_balance_loaded = true
