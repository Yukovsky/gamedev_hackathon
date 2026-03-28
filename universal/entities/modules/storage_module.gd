extends "res://entities/modules/module_base.gd"
class_name StorageModule


func _init() -> void:
	module_id = Constants.MODULE_STORAGE
	grid_size = Vector2i.ONE
	metal_cost = Constants.get_module_cost(module_id)
	sprite_color = Color(0.57, 0.67, 0.78, 1.0)
