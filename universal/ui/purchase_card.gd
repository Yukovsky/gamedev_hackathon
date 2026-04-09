extends PanelContainer
## Компонент карточки товара для магазинов.
## Отображает товар и обрабатывает клики для покупки.

signal item_selected(module_type: String, cost: int)

@export var module_type: String = "hull"  # Тип модуля для покупки
@export var item_name: String = "КОРПУС"
@export var item_description: String = "Увеличьте размер корабля"
@export var item_icon: String = "📦"

var _cost: int = 0
var _is_affordable: bool = false

var name_label: Label
var description_label: Label
var price_label: Label
var icon_label: Label

func _ready() -> void:
	# Находим дочерние элементы по имени
	name_label = find_child("Name", true, false) as Label
	description_label = find_child("Desc", true, false) as Label
	price_label = find_child("Price", true, false) as Label
	icon_label = find_child("Icon", true, false) as Label
	
	# Подключаемся к обновлениям ресурсов
	if GameEvents:
		GameEvents.resource_changed.connect(_on_resource_changed)
	
	# Подключаем клик по карточке
	gui_input.connect(_on_gui_input)
	mouse_filter = MOUSE_FILTER_STOP
	
	# Инициализируем отображение
	_update_display()

func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	if not _is_affordable:
		if AudioManager:
			AudioManager.play_ui_error()
		return
	
	# Эмитируем событие покупки через Event Bus
	if AudioManager:
		AudioManager.play_ui_open()
	if GameEvents:
		GameEvents.build_requested.emit(module_type, Vector2.ZERO)
	item_selected.emit(module_type, _cost)

func _on_resource_changed(_type: String, _new_total: int) -> void:
	if _type == "metal":
		_update_affordability()

func _update_display() -> void:
	"""Обновляет визуальное отображение карточки."""
	if icon_label:
		icon_label.text = item_icon
	
	if name_label:
		name_label.text = item_name
	
	if description_label:
		description_label.text = item_description
	
	# Получаем текущую стоимость модуля
	if ResourceManager:
		_cost = ResourceManager.get_current_module_cost(module_type)
	
	if price_label:
		price_label.text = "%d +" % _cost
	
	_update_affordability()

func _update_affordability() -> void:
	"""Обновляет доступность товара на основе количества металла."""
	if not ResourceManager:
		return
	
	var metal = ResourceManager.metal
	_is_affordable = metal >= _cost
	
	# Обновляем цвет цены
	if price_label:
		if _is_affordable:
			price_label.add_theme_color_override("font_color", Color(0.941, 0.816, 0.125))  # Золотой
		else:
			price_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))  # Красный

func set_module_data(type: String, name: String, description: String, icon: String) -> void:
	"""Устанавливает данные для отображения на карточке."""
	module_type = type
	item_name = name
	item_description = description
	item_icon = icon
	
	if is_node_ready():
		_update_display()

func refresh() -> void:
	"""Обновляет отображение карточки (используется при изменении цен)."""
	_update_display()
