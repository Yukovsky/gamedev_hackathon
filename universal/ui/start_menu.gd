extends Control

@onready var btn_start: Button = %BtnStart
@onready var btn_quit: Button = %BtnQuit

func _ready() -> void:
	print("--- МЕНЮ ГОТОВО ---")
	
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)
	
	# Проверка наведения для отладки
	btn_start.mouse_entered.connect(func(): print("МЫШЬ НА КНОПКЕ 'ИГРАТЬ'"))
	btn_quit.mouse_entered.connect(func(): print("МЫШЬ НА КНОПКЕ 'ВЫХОД'"))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("КЛИК В МЕНЮ (ПОЗИЦИЯ: ", event.position, ")")

func _on_btn_start_pressed() -> void:
	print("--- ЗАПУСК ИГРЫ ---")
	get_tree().change_scene_to_file("res://main.tscn")

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
