extends Node
## Менеджер ресурсов: управляет Металлом
## Все константы баланса загружаются из Constants.gd (которые загружают .tres конфиги)

var metal: int = 0
var max_metal: int = 0

func _ready() -> void:
	# Инициализируем начальные значения из Constants
	metal = Constants.get_resource_initial_metal()
	max_metal = Constants.get_resource_max_metal()
	
	GameEvents.garbage_clicked.connect(_on_garbage_clicked)
	# Мы слушаем ПОСТРОЕННЫЕ модули, чтобы обновлять лимиты
	GameEvents.module_built.connect(_on_module_built)
	call_deferred("_initialize_ui")

func _initialize_ui() -> void:
	GameEvents.resource_changed.emit("metal", metal)

func add_metal(amount: int) -> void:
	metal = min(metal + amount, max_metal)
	GameEvents.resource_changed.emit("metal", metal)

func spend_metal(amount: int) -> bool:
	if metal >= amount:
		metal -= amount
		GameEvents.resource_changed.emit("metal", metal)
		return true
	return false

func _on_garbage_clicked(amount: int) -> void:
	add_metal(amount)

func _on_module_built(module_type: String, _pos: Vector2) -> void:
	if module_type == Constants.MODULE_HULL:
		# Модуль корпуса увеличивает лимит металла (читаем бонус из Constants)
		max_metal += Constants.get_hull_metal_bonus()
		GameEvents.resource_changed.emit("metal", metal)
		print("Resource Manager: Hull built! New max metal: ", max_metal)
