extends CanvasLayer

@onready var btn_start: Button = %BtnStart
@onready var btn_training: Button = %BtnTraining
@onready var btn_exit: Button = %BtnExit

const MAIN_SCENE_PRIMARY: String = "res://main.tscn"
const MAIN_SCENE_FALLBACK: String = "res://universal/main.tscn"
const TRAINING_SCENE: String = "res://ui/tutorial_first_call_mode.tscn"

func _ready() -> void:
	print("--- МЕНЮ ЗАГРУЖЕНО ---")
	_configure_button_pivot(btn_start)
	_configure_button_pivot(btn_training)
	_configure_button_pivot(btn_exit)
	btn_start.resized.connect(_on_button_resized.bind(btn_start))
	btn_training.resized.connect(_on_button_resized.bind(btn_training))
	btn_exit.resized.connect(_on_button_resized.bind(btn_exit))
	
	# Привязываем сигналы
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_training.pressed.connect(_on_btn_training_pressed)
	btn_exit.pressed.connect(_on_btn_exit_pressed)
	
	# Добавляем анимации hover
	btn_start.mouse_entered.connect(_on_btn_hover.bind(btn_start, true))
	btn_start.mouse_exited.connect(_on_btn_hover.bind(btn_start, false))
	btn_training.mouse_entered.connect(_on_btn_hover.bind(btn_training, true))
	btn_training.mouse_exited.connect(_on_btn_hover.bind(btn_training, false))
	btn_exit.mouse_entered.connect(_on_btn_hover.bind(btn_exit, true))
	btn_exit.mouse_exited.connect(_on_btn_hover.bind(btn_exit, false))
	
	# Пульсирующая анимация для кнопки старта
	_start_pulse_animation()


func _configure_button_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _on_button_resized(button: Button) -> void:
	_configure_button_pivot(button)

func _start_pulse_animation() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(btn_start, "modulate:a", 0.7, 1.5)
	tween.tween_property(btn_start, "modulate:a", 1.0, 1.5)

func _on_btn_start_pressed() -> void:
	var target_scene: String = MAIN_SCENE_PRIMARY if ResourceLoader.exists(MAIN_SCENE_PRIMARY) else MAIN_SCENE_FALLBACK
	print("--- СМЕНА СЦЕНЫ НА %s ---" % target_scene)
	AudioManager.play_ui_open()
	get_tree().change_scene_to_file(target_scene)

func _on_btn_training_pressed() -> void:
	if not ResourceLoader.exists(TRAINING_SCENE):
		push_warning("Training scene not found: %s" % TRAINING_SCENE)
		return
	print("--- СМЕНА СЦЕНЫ НА %s ---" % TRAINING_SCENE)
	AudioManager.play_ui_open()
	get_tree().change_scene_to_file(TRAINING_SCENE)

func _on_btn_exit_pressed() -> void:
	print("--- ВЫХОД ИЗ ИГРЫ ---")
	get_tree().quit()

func _on_btn_hover(button: Button, entered: bool) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	if entered:
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)
	else:
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
