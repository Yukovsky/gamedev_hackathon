extends Control
## Контроллер нижней панели навигации.
## Управляет переключением между 5 экранами через кнопки или свайп.

signal screen_changed(new_index: int)

const SCREEN_COUNT = 5
const SWIPE_MIN_DISTANCE = 50.0  # Минимальное расстояние для свайпа

@export var active_button_color: Color = Color(0.4, 0.8, 1.0, 1.0)  # Голубой для активной кнопки
@export var inactive_button_color: Color = Color(0.5, 0.5, 0.5, 0.7)  # Серый для неактивных

@onready var nav_buttons: Array[Button] = []
var _current_screen_index: int = 2  # Начальный экран - главный (индекс 2)
var _swipe_start_position: Vector2 = Vector2.ZERO
var _is_swiping: bool = false

func _ready() -> void:
	# Собираем кнопки навигации из дочерних узлов
	var button_container = get_child(0) if get_child_count() > 0 else null
	if button_container == null:
		button_container = $Margin/HBoxContainer if has_node("Margin/HBoxContainer") else null
	
	if button_container == null:
		push_error("BottomNavigationController: не найден контейнер с кнопками")
		return
	
	for i in range(SCREEN_COUNT):
		var btn = button_container.get_child(i) if i < button_container.get_child_count() else null
		if btn == null or not (btn is Button):
			push_error("BottomNavigationController: кнопка %d не найдена" % i)
			continue
		
		nav_buttons.append(btn)
		btn.pressed.connect(_on_nav_button_pressed.bind(i))
	
	# Обновляем визуальное состояние кнопок
	_update_button_states()

func _input(event: InputEvent) -> void:
	# Обработка горизонтального свайпа
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start_position = event.position
			_is_swiping = true
		else:
			if _is_swiping:
				_handle_swipe(event.position)
			_is_swiping = false
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_swipe_start_position = event.position
			_is_swiping = true
		else:
			if _is_swiping:
				_handle_swipe(event.position)
			_is_swiping = false

func _on_nav_button_pressed(index: int) -> void:
	if index < 0 or index >= SCREEN_COUNT:
		return
	if index == 4:  # Экран дерева технологий - недоступен
		if AudioManager:
			AudioManager.play_ui_error()
		return
	
	_set_current_screen(index)

func _handle_swipe(end_position: Vector2) -> void:
	var swipe_vector = end_position - _swipe_start_position
	var horizontal_distance = swipe_vector.x
	var vertical_distance = abs(swipe_vector.y)
	
	# Проверяем, что это горизонтальный свайп
	if vertical_distance > horizontal_distance:
		return
	
	# Проверяем минимальное расстояние свайпа
	if abs(horizontal_distance) < SWIPE_MIN_DISTANCE:
		return
	
	# Определяем направление
	if horizontal_distance > 0:  # Свайп вправо - к предыдущему экрану
		_navigate_to(_current_screen_index - 1)
	else:  # Свайп влево - к следующему экрану
		_navigate_to(_current_screen_index + 1)

func _navigate_to(index: int) -> void:
	# Ограничиваем диапазон
	index = clampi(index, 0, SCREEN_COUNT - 1)
	
	# Проверяем доступность
	if index == 4:  # Экран дерева технологий
		return
	
	_set_current_screen(index)

func _set_current_screen(index: int) -> void:
	if index == _current_screen_index:
		return
	
	_current_screen_index = index
	_update_button_states()
	screen_changed.emit(_current_screen_index)

func _update_button_states() -> void:
	for i in range(nav_buttons.size()):
		var btn = nav_buttons[i]
		if i == 4:  # Кнопка дерева - всегда неактивна и недоступна
			btn.disabled = true
			btn.self_modulate = Color(0.3, 0.3, 0.3, 0.3)
		elif i == _current_screen_index:
			btn.disabled = false
			btn.self_modulate = active_button_color
		else:
			btn.disabled = false
			btn.self_modulate = inactive_button_color

func get_current_screen() -> int:
	return _current_screen_index

func set_current_screen(index: int) -> void:
	_set_current_screen(index)
