extends CanvasLayer

@onready var btn_start: Button = %BtnStart

func _ready() -> void:
	print("--- МЕНЮ ЗАГРУЖЕНО ---")
	
	# Привязываем сигнал
	btn_start.pressed.connect(_on_btn_start_pressed)

func _on_btn_start_pressed() -> void:
	print("--- СМЕНА СЦЕНЫ НА res://main.tscn ---")
	AudioManager.play_ui_open()
	get_tree().change_scene_to_file("res://main.tscn")
