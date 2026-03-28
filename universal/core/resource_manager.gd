extends Node
## Менеджер ресурсов: управляет Металлом

var metal: int = 0
var max_metal: int = 50

func _ready() -> void:
	GameEvents.garbage_clicked.connect(_on_garbage_clicked)
	# Мы будем слушать события постройки, чтобы увеличивать лимиты
	GameEvents.build_requested.connect(_on_build_requested)
	call_deferred("_initialize_ui")

func _initialize_ui() -> void:
	GameEvents.resource_changed.emit("metal", metal, max_metal)

func add_metal(amount: int) -> void:
	metal = min(metal + amount, max_metal)
	GameEvents.resource_changed.emit("metal", metal, max_metal)

func spend_metal(amount: int) -> bool:
	if metal >= amount:
		metal -= amount
		GameEvents.resource_changed.emit("metal", metal, max_metal)
		return true
	return false

func _on_garbage_clicked(amount: int) -> void:
	add_metal(amount)

func _on_build_requested(type: String, _pos: Vector2) -> void:
	if type == "generator":
		# Генератор увеличивает лимит металла (например, на 50)
		if spend_metal(15): # Цена генератора
			max_metal += 50
			GameEvents.resource_changed.emit("metal", metal, max_metal)
			print("Generator built! New max metal: ", max_metal)
	elif type == "hull":
		if spend_metal(5):
			print("Hull built request sent")
			# Логика спавна клетки должна быть в GameBoard
	elif type == "collector":
		if spend_metal(25):
			print("Collector built request sent")
