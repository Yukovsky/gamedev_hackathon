extends Node
## Глобальные константы и ID для проекта

# ========== Типы модулей ==========
enum ModuleType {
	RESOURCE = 0,  # Добывает ресурсы
	COMBAT = 1,    # Боевая система
	STORAGE = 2,   # Хранилище ресурсов
}

# Строковые ID модулей для более удобного использования
const MODULE_IDS = {
	"resource": "resource",
	"combat": "combat",
	"storage": "storage",
}

# ========== Параметры ядра ==========
const BASE_METAL_PER_CLICK: int = 10
const BASE_ENERGY_PER_CLICK: int = 5

# ========== UI Слои ==========
const UI_LAYER_HUD: int = 0
const UI_LAYER_MENU: int = 1
const UI_LAYER_POPUP: int = 2
