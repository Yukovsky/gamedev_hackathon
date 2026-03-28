extends Node

var metal: int = 0:
	set(v):
		metal = clamp(v, 0, max_metal)
		GameEvents.resource_changed.emit("metal", metal, max_metal)

var max_metal: int = 10:
	set(v):
		max_metal = v
		GameEvents.resource_changed.emit("metal", metal, max_metal)

func _ready():
	GameEvents.metal_collected.connect(_on_metal_collected)
	GameEvents.metal_limit_updated.connect(_on_limit_updated)

func _on_metal_collected(amount: int):
	metal += amount

func _on_limit_updated(new_limit: int):
	max_metal = new_limit

func spend_metal(amount: int) -> bool:
	if metal >= amount:
		metal -= amount
		return true
	return false
