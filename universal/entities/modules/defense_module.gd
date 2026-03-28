extends "res://entities/modules/module_base.gd"
class_name DefenseModule


func _init() -> void:
	module_id = Constants.MODULE_DEFENSE
	grid_size = Vector2i.ONE
	metal_cost = Constants.get_module_cost(module_id)
	defence_bonus = 1
	sprite_color = Color(0.82, 0.37, 0.78, 1.0)
