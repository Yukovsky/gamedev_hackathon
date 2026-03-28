extends Resource
class_name ModuleData

enum ModuleType {
	NONE,
	CORE,
	CARGO,
	COLLECTOR,
	HULL
}

@export var type: ModuleType
@export var cost: int
@export var module_name: String
@export var description: String
