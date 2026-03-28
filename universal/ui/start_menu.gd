extends CanvasLayer

@onready var btn_start: Button = %BtnStart
@onready var btn_exit: Button = %BtnExit

func _ready() -> void:
	print("--- МЕНЮ ЗАГРУЖЕНО ---")
	btn_start.add_theme_font_size_override("font_size", 100)
	btn_exit.add_theme_font_size_override("font_size", 60)
	
	# Привязываем сигналы
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_exit.pressed.connect(_on_btn_exit_pressed)
	
	# Добавляем анимации hover
	btn_start.mouse_entered.connect(_on_btn_hover.bind(btn_start, true))
	btn_start.mouse_exited.connect(_on_btn_hover.bind(btn_start, false))
	btn_exit.mouse_entered.connect(_on_btn_hover.bind(btn_exit, true))
	btn_exit.mouse_exited.connect(_on_btn_hover.bind(btn_exit, false))
	
	# Пульсирующая анимация для кнопки старта
	_start_pulse_animation()

func _start_pulse_animation() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(btn_start, "modulate:a", 0.7, 1.5)
	tween.tween_property(btn_start, "modulate:a", 1.0, 1.5)

func _on_btn_start_pressed() -> void:
	print("--- СМЕНА СЦЕНЫ НА res://main.tscn ---")
	AudioManager.play_ui_open()
	get_tree().change_scene_to_file("res://main.tscn")

func _on_btn_exit_pressed() -> void:
	print("--- ВЫХОД ИЗ ИГРЫ ---")
	AudioManager.play_ui_click()
	get_tree().quit()

func _on_btn_hover(button: Button, entered: bool) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	if entered:
		AudioManager.play_ui_click()
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)
	else:
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
