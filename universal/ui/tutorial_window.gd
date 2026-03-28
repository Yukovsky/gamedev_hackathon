extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var dialog_text: RichTextLabel = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DialogText
@onready var name_label: Label = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NameLabel

var tutorial_steps: Array[String] = [
	"Капитан, вы меня слышите? Это Надя, ваш бортовой ИИ.",
	"Наш корабль серьезно пострадал. Мы застряли в секторе космического мусора.",
	"Чтобы выжить, нам нужно собирать обломки. Тапайте по пролетающему мусору, чтобы добыть Металл!",
	"Используйте Металл для постройки модулей. Постройте Сборщик, и он начнет собирать мусор автоматически."
]

var current_step: int = 0
var is_typing: bool = false
var typing_tween: Tween

func _ready() -> void:
	hide() 
	GameEvents.game_started.connect(start_tutorial)
	# Мы удалили старую подписку на gui_input, теперь все работает через _input()

func start_tutorial() -> void:
	show()
	current_step = 0
	_show_current_step()

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
	print("Обучение завершено!")
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
