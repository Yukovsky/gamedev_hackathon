extends Resource
class_name RaiderWaveRow
## Одна строка конфигурации волны налётчиков.
## Определяет состав врагов для заданного диапазона построек.

@export_group("Building Range")
@export var buildings_min: int = 0
@export var buildings_max: int = 999

@export_group("Enemy Composition")
@export var normal_count: int = 0
@export var sprinter_count: int = 0
@export var tank_count: int = 0

@export_group("Enemy Stats")
@export var normal_hp: int = 150
@export var sprinter_hp: int = 100
@export var tank_hp: int = 400

@export_group("Spawn Limits")
@export var max_active: int = 1


func get_enemy_set() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	if normal_count > 0:
		result.append({"type": "normal", "count": normal_count})
	if sprinter_count > 0:
		result.append({"type": "sprinter", "count": sprinter_count})
	if tank_count > 0:
		result.append({"type": "tank", "count": tank_count})
	
	return result


func get_hp_for_role(role_name: String) -> int:
	match role_name.to_lower():
		"sprinter":
			return max(1, sprinter_hp)
		"tank":
			return max(1, tank_hp)
		_:
			return max(1, normal_hp)
