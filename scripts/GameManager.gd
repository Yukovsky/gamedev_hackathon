extends Node

signal metal_changed(current, limit)
signal ship_updated()

const GRID_SIZE = Vector2i(12, 20)
const CELL_SIZE = 90
const MAX_JUNK = 5

enum ModuleType {
	NONE,
	CORE,
	CARGO,
	COLLECTOR,
	HULL # Opened cell where something can be built
}

var metal: int = 0:
	set(v):
		metal = clamp(v, 0, max_metal)
		metal_changed.emit(metal, max_metal)

var max_metal: int = 10:
	set(v):
		max_metal = v
		metal_changed.emit(metal, max_metal)

# Dictionary of Vector2i -> ModuleType
var ship_modules = {}

func _ready():
	setup_initial_ship()

func setup_initial_ship():
	# Center the ship in the 12x20 grid
	# Center is around (6, 10)
	var start_pos = Vector2i(5, 8)
	
	# Initial scheme:
	# [CORE][CORE]
	# [COLLECT][NONE]
	# [CARGO][NONE]
	
	add_module(start_pos + Vector2i(0, 0), ModuleType.CORE)
	add_module(start_pos + Vector2i(1, 0), ModuleType.CORE)
	add_module(start_pos + Vector2i(0, 1), ModuleType.COLLECTOR)
	add_module(start_pos + Vector2i(0, 2), ModuleType.CARGO)
	
	# Also mark some neighboring cells as HULL? 
	# Actually the instructions say "Расширение корпуса" opens a cell.
	# So we don't start with any HULL, only modules.
	
	update_max_metal()
	metal = 0

func add_module(pos: Vector2i, type: ModuleType):
	ship_modules[pos] = type
	if type == ModuleType.CARGO:
		update_max_metal()
	ship_updated.emit()

func update_max_metal():
	var cargo_count = 0
	for pos in ship_modules:
		if ship_modules[pos] == ModuleType.CARGO:
			cargo_count += 1
	max_metal = 10 + (cargo_count * 20)

func can_expand_to(pos: Vector2i) -> bool:
	if ship_modules.has(pos):
		return false
	
	# Max ship size 6x6 check? 
	# "максимальный размер корабля: 6 × 6"
	# Let's track the bounding box.
	var min_x = 999
	var max_x = -999
	var min_y = 999
	var max_y = -999
	
	if ship_modules.is_empty():
		return true # Should not happen after ready
		
	for p in ship_modules:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	
	# Provisional new box
	var n_min_x = min(min_x, pos.x)
	var n_max_x = max(max_x, pos.x)
	var n_min_y = min(min_y, pos.y)
	var n_max_y = max(max_y, pos.y)
	
	if (n_max_x - n_min_x + 1) > 6 or (n_max_y - n_min_y + 1) > 6:
		return false

	# Check adjacent to any existing module
	var neighbors = [
		pos + Vector2i(1, 0),
		pos + Vector2i(-1, 0),
		pos + Vector2i(0, 1),
		pos + Vector2i(0, -1)
	]
	
	for n in neighbors:
		if ship_modules.has(n):
			return true
	return false

func get_module_at(pos: Vector2i) -> ModuleType:
	return ship_modules.get(pos, ModuleType.NONE)

func build_module(pos: Vector2i, type: ModuleType):
	var cost = get_module_cost(type)
	
	# Rules:
	# 1. HULL can only be placed on an empty cell adjacent to ship.
	# 2. Others can only be placed on a HULL cell.
	
	if type == ModuleType.HULL:
		if can_expand_to(pos) and metal >= cost:
			metal -= cost
			add_module(pos, type)
			return true
	else:
		if get_module_at(pos) == ModuleType.HULL and metal >= cost:
			metal -= cost
			add_module(pos, type)
			return true
			
	return false

func get_module_cost(type: ModuleType) -> int:
	match type:
		ModuleType.HULL: return 3
		ModuleType.CARGO: return 5
		ModuleType.COLLECTOR: return 10
	return 0

func collect_junk():
	metal += 1
