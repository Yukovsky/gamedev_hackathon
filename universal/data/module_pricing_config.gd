extends Resource
class_name ModulePricingConfig
## Конфигурация стоимости модулей по итерациям постройки.
## Data-Driven подход: баланс редактируется в Inspector, не в коде.

@export_group("Reactor Costs")
@export var reactor_costs: Array[int] = [350, 525, 788, 1182, 1772, 2658, 3987, 5981, 8971, 13456]

@export_group("Hull Costs")
@export var hull_costs: Array[int] = [75, 98, 127, 165, 215, 279, 363, 471, 612, 796]

@export_group("Collector Costs")
@export var collector_costs: Array[int] = [100, 130, 169, 220, 286, 372, 483, 628, 816, 1061]

@export_group("Turret Costs")
@export var turret_costs: Array[int] = [240, 312, 406, 528, 686, 892, 1159, 1506, 1958, 2546]


func get_cost_for_module(module_id: String, iteration: int) -> int:
	var costs: Array[int] = _get_costs_array(module_id)
	if costs.is_empty():
		return 0
	
	var index: int = clampi(iteration, 0, costs.size() - 1)
	return costs[index]


func has_incremental_pricing(module_id: String) -> bool:
	return not _get_costs_array(module_id).is_empty()


func _get_costs_array(module_id: String) -> Array[int]:
	match module_id:
		"reactor":
			return reactor_costs
		"hull":
			return hull_costs
		"collector":
			return collector_costs
		"turret":
			return turret_costs
		_:
			return []
