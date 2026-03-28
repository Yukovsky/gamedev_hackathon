extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var dialog_text: RichTextLabel = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DialogText
@onready var name_label: Label = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NameLabel

var intro_steps: Array[String] = [
	"Капитан, вы меня слышите? Это Надя, ваш бортовой ИИ.",
	"Наш корабль серьезно пострадал. Мы застряли в секторе космического мусора.",
	"Чтобы выжить, нам нужно собирать обломки. Тапайте по пролетающему мусору, чтобы добыть Металл!",
	"Используйте Металл для постройки модулей. Постройте Сборщик, и он начнет собирать мусор автоматически."
]
var raider_warning_steps: Array[String] = [
	"Капитан, тревога! Это вражеский налётчик. Он хочет забрать наши ресурсы.",
	"Чтобы отбиться, кликайте прямо по врагу, как по мусору.",
	"Для автоматизации постройте турели: их можно купить в магазине."
]

var tutorial_steps: Array[String] = []

var current_step: int = 0
var is_typing: bool = false
var typing_tween: Tween
var _pause_state_before_tutorial: bool = false
var _pause_applied: bool = false
var _raider_warning_shown: bool = false
var _pending_raider_warning: bool = false

func _ready() -> void:
	# Диалог должен оставаться интерактивным даже когда игра на паузе.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide() 
	GameEvents.game_started.connect(start_tutorial)
	GameEvents.raider_spawned.connect(_on_raider_spawned)
	# Мы удалили старую подписку на gui_input, теперь все работает через _input()

func start_tutorial() -> void:
	_start_dialog(intro_steps)


func _start_dialog(steps: Array[String]) -> void:
	if steps.is_empty():
		return

	if not _pause_applied:
		_pause_state_before_tutorial = get_tree().paused
		get_tree().paused = true
		_pause_applied = true

	tutorial_steps = steps
	show()
	current_step = 0
	_show_current_step()


func _on_raider_spawned(_position: Vector2) -> void:
	if _raider_warning_shown:
		return

	_raider_warning_shown = true
	if visible:
		_pending_raider_warning = true
		return
	# Небольшая задержка, чтобы игрок успел увидеть появление врага
	await get_tree().create_timer(1.5).timeout
	# Если за это время открылся другой диалог — поставим предупреждение в очередь
	if visible:
		_pending_raider_warning = true
		return

	_start_dialog(raider_warning_steps)

func _show_current_step() -> void:
	if current_step >= tutorial_steps.size():
		_end_tutorial()
		return

	is_typing = true
	dialog_text.text = tutorial_steps[current_step]
	dialog_text.visible_ratio = 0.0 # Сбрасываем видимость текста в ноль
	
	if typing_tween:
		typing_tween.kill()
		
	typing_tween = create_tween()
	var duration = tutorial_steps[current_step].length() * 0.03
	typing_tween.tween_property(dialog_text, "visible_ratio", 1.0, duration)
	typing_tween.finished.connect(func(): is_typing = false)

func _end_tutorial() -> void:
	hide()
	if _pause_applied:
		get_tree().paused = _pause_state_before_tutorial
		_pause_applied = false
	print("Обучение завершено!")
	if _pending_raider_warning:
		_pending_raider_warning = false
		_start_dialog(raider_warning_steps)
	# Здесь можно запустить спавн мусора/врагов

# ==========================================
# ГЛОБАЛЬНЫЙ ПЕРЕХВАТ КЛИКОВ
# ==========================================
func _input(event: InputEvent) -> void:
	# Если Надя спрятана, мы вообще не вмешиваемся в клики
	if not visible:
		return

	# Проверяем, что это левый клик мыши или тап по экрану смартфона
	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		# МАГИЯ: Забираем клик себе! Теперь он не пройдет сквозь интерфейс в игру.
		get_viewport().set_input_as_handled() 
		
		if is_typing:
			# Если текст еще печатается - моментально показываем его весь
			if typing_tween:
				typing_tween.kill()
			dialog_text.visible_ratio = 1.0
			is_typing = false
		else:
			# Если текст уже напечатан - идем к следующей реплике
			current_step += 1
			_show_current_step()
