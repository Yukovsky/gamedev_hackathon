extends Control

@onready var btn_start: Button = %BtnStart

func _ready() -> void:
	print("--- МЕНЮ ЗАПУЩЕНО ---")
	# Убедимся, что кнопки видны и активны
	btn_start.disabled = false
	btn_start.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Прямая привязка сигнала
	btn_start.pressed.connect(_on_btn_start_pressed)

func _process(_delta: float) -> void:
	# Если клик прошел мимо кнопки, но в окно - мы это увидим
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print("Обнаружен зажатый клик (Mouse Left) в кадре")

func _on_btn_start_pressed() -> void:
	print("!!! КНОПКА ИГРАТЬ СРАБОТАЛА !!!")
	get_tree().change_scene_to_file("res://main.tscn")
