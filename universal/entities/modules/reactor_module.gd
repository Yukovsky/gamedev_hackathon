extends "res://entities/modules/module_base.gd"
class_name ReactorModule


func _init() -> void:
	module_id = Constants.MODULE_REACTOR
	grid_size = Vector2i.ONE
	metal_cost = Constants.MODULE_COST_METAL[module_id]
	energy_radius_cells = 1
	sprite_color = Color(0.95, 0.74, 0.20, 1.0)
