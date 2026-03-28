extends CanvasLayer

@onready var btn_start: Button = %BtnStart

func _ready() -> void:
	print("--- МЕНЮ ЗАГРУЖЕНО ---")
	
	# Привязываем сигнал
	btn_start.pressed.connect(_on_btn_start_pressed)

func _on_btn_start_pressed() -> void:
	print("--- СМЕНА СЦЕНЫ НА res://main.tscn (или universal/main.tscn) ---")
	var path = "res://main.tscn"
	if not ResourceLoader.exists(path):
		path = "res://universal/main.tscn"
	if not ResourceLoader.exists(path):
		push_error("MAIN SCENE NOT FOUND: " + path)
		return
	get_tree().change_scene_to_file(path)
	print("Scene changed to: " + path)
