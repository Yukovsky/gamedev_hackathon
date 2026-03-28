extends "res://entities/modules/module_base.gd"
class_name CoreModule

signal defence_value_changed(new_total: int)

@export var base_defence: int = Constants.CORE_BASE_DEFENCE

var defence: int = 0
var discounted_builds_left: int = 0


func _init() -> void:
	module_id = Constants.MODULE_CORE
	grid_size = Vector2i(2, 1)
	metal_cost = 0
	sprite_color = Color(0.86, 0.26, 0.26, 1.0)


func _ready() -> void:

	defence = base_defence
	defence_value_changed.emit(defence)
	GameEvents.defence_changed.emit(defence)


func add_defence(amount: int) -> void:
	defence += max(0, amount)
	defence_value_changed.emit(defence)
	GameEvents.defence_changed.emit(defence)


func resolve_collision(hazard_class: int) -> Dictionary:
	var target_hazard: int = max(0, hazard_class)
	var success: bool = defence >= target_hazard
	var modules_lost: int = 0
	var discount_builds: int = 0

	if success:
		discount_builds = int(floor(float(target_hazard) / 10.0))
		discounted_builds_left = discount_builds
	else:
		modules_lost = int(floor(float(target_hazard - defence) / 10.0))

	GameEvents.collision_resolved.emit(target_hazard, success, modules_lost, discount_builds)

	return {
		"success": success,
		"modules_lost": modules_lost,
		"discounted_builds": discount_builds,
	}


func get_build_discount_multiplier() -> float:
	if discounted_builds_left > 0:
		return 0.5
	return 1.0


func consume_build_discount() -> void:
	if discounted_builds_left > 0:
		discounted_builds_left -= 1
