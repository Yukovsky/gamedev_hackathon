extends Control
class_name BuildPanel

signal build_option_selected(module_type: String)

@export var auto_hide_after_select: bool = true


func request_build(module_type: String) -> void:
	if module_type == "":
		return

	GameEvents.build_requested.emit(module_type, Vector2.ZERO)
	build_option_selected.emit(module_type)

	if auto_hide_after_select:
		visible = false
