extends Resource
class_name CoreUpgradeConfig
## Конфигурация улучшений ядра: награды за мусор и стоимость апгрейдов.
## Data-Driven подход: баланс редактируется в Inspector, не в коде.

@export_group("Upgrade Costs")
@export var upgrade_costs: Array[int] = [375, 469, 586, 733, 916]

@export_group("Level 0 Rewards")
@export var level_0_trash_1: int = 17
@export var level_0_trash_2: int = 13
@export var level_0_trash_3: int = 20

@export_group("Level 1 Rewards")
@export var level_1_trash_1: int = 21
@export var level_1_trash_2: int = 16
@export var level_1_trash_3: int = 25

@export_group("Level 2 Rewards")
@export var level_2_trash_1: int = 27
@export var level_2_trash_2: int = 20
@export var level_2_trash_3: int = 31

@export_group("Level 3 Rewards")
@export var level_3_trash_1: int = 33
@export var level_3_trash_2: int = 25
@export var level_3_trash_3: int = 39

@export_group("Level 4 Rewards")
@export var level_4_trash_1: int = 42
@export var level_4_trash_2: int = 32
@export var level_4_trash_3: int = 49

@export_group("Level 5 Rewards")
@export var level_5_trash_1: int = 52
@export var level_5_trash_2: int = 61
@export var level_5_trash_3: int = 40


func get_max_level() -> int:
	return 5


func get_upgrade_cost(current_level: int) -> int:
	if current_level < 0:
		return upgrade_costs[0] if not upgrade_costs.is_empty() else -1
	if current_level >= upgrade_costs.size():
		return -1
	return upgrade_costs[current_level]


func get_reward_for_debris(debris_type: int, level: int) -> int:
	var clamped_level: int = clampi(level, 0, get_max_level())
	
	match clamped_level:
		0:
			return _get_level_reward(debris_type, level_0_trash_1, level_0_trash_2, level_0_trash_3)
		1:
			return _get_level_reward(debris_type, level_1_trash_1, level_1_trash_2, level_1_trash_3)
		2:
			return _get_level_reward(debris_type, level_2_trash_1, level_2_trash_2, level_2_trash_3)
		3:
			return _get_level_reward(debris_type, level_3_trash_1, level_3_trash_2, level_3_trash_3)
		4:
			return _get_level_reward(debris_type, level_4_trash_1, level_4_trash_2, level_4_trash_3)
		5:
			return _get_level_reward(debris_type, level_5_trash_1, level_5_trash_2, level_5_trash_3)
		_:
			return _get_level_reward(debris_type, level_0_trash_1, level_0_trash_2, level_0_trash_3)


func _get_level_reward(debris_type: int, trash_1: int, trash_2: int, trash_3: int) -> int:
	match debris_type:
		0:  # TRASH_1
			return trash_1
		1:  # TRASH_2
			return trash_2
		2:  # TRASH_3
			return trash_3
		_:
			return trash_1
