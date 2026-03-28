extends Control

@onready var btn_start: Button = %BtnStart
@onready var btn_quit: Button = %BtnQuit
@onready var title: Label = %Title
@onready var buttons_container: VBoxContainer = %ButtonsContainer

func _ready() -> void:
	print("Меню загружено. Ищем кнопки...")
	
	# Начальное состояние для анимации
	title.modulate.a = 0
	buttons_container.modulate.a = 0
	
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)
	
	_animate_appearance()

func _animate_appearance() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(title, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(buttons_container, "modulate:a", 1.0, 1.0).set_delay(0.5).set_trans(Tween.TRANS_SINE)
	print("Анимация появления запущена")

func _on_btn_start_pressed() -> void:
	print("Нажата кнопка ИГРАТЬ")
	# Прямой переход без долгого ожидания для надежности
	var error = get_tree().change_scene_to_file("res://main.tscn")
	if error != OK:
		print("ОШИБКА ЗАГРУЗКИ СЦЕНЫ: ", error)

func _on_btn_quit_pressed() -> void:
	print("Нажата кнопка ВЫХОД")
	get_tree().quit()
