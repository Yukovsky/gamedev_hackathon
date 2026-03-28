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

const MODULE_IDS = {
	"core": MODULE_CORE,
	"collector": MODULE_COLLECTOR,
	"reactor": MODULE_REACTOR,
	"storage": MODULE_STORAGE,
	"defense": MODULE_DEFENSE,
}

const MODULE_COST_METAL = {
	MODULE_COLLECTOR: 100,
	MODULE_REACTOR: 400,
	MODULE_STORAGE: 60,
	MODULE_DEFENSE: 120,
}

# ========== Параметры ядра ==========
const BASE_METAL_PER_CLICK: int = 10
const BASE_ENERGY_PER_CLICK: int = 5
const CORE_BASE_DEFENCE: int = 10
const CORE_RADIUS_CELLS: int = 1

# ========== UI Слои ==========
const UI_LAYER_HUD: int = 0
const UI_LAYER_MENU: int = 1
const UI_LAYER_POPUP: int = 2
