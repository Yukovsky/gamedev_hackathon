extends Node2D

const CELL_SIZE = 90
const MAX_SHIP_SIZE = 6

# Dictionary of Vector2i -> ModuleType
var modules = {}

@onready var modules_container = $Modules
var ship_module_scene = preload("res://entities/modules/ship_module.tscn")

var hull_stats = preload("res://data/room_stats/hull.tres")
var cargo_stats = preload("res://data/room_stats/cargo.tres")
var collector_stats = preload("res://data/room_stats/collector.tres")

func _ready():
	GameEvents.build_requested.connect(_on_build_requested)
	setup_initial_ship()

func setup_initial_ship():
	var start = Vector2i(5, 8)
	add_module(start + Vector2i(0, 0), 1) # CORE
	add_module(start + Vector2i(1, 0), 1) # CORE
	add_module(start + Vector2i(0, 1), 3) # COLLECTOR
	add_module(start + Vector2i(0, 2), 2) # CARGO
	update_capacity()

func add_module(pos: Vector2i, type: int):
	modules[pos] = type
	_update_visuals()
	GameEvents.ship_updated.emit()
	if is_inside_tree():
		SoundManager.play_build()
	if type == 2: # CARGO
		update_capacity()

func _update_visuals():
	for child in modules_container.get_children():
		child.queue_free()
	
	for pos in modules:
		var type = modules[pos]
		var inst = ship_module_scene.instantiate()
		modules_container.add_child(inst)
		inst.setup(pos, type)

func update_capacity():
	var cargo_count = 0
	for pos in modules:
		if modules[pos] == 2: # CARGO
			cargo_count += 1
	var new_limit = 10 + (cargo_count * 20)
	GameEvents.metal_limit_updated.emit(new_limit)

func can_expand_to(pos: Vector2i) -> bool:
	if modules.has(pos): return false
	
	var min_x = pos.x; var max_x = pos.x
	var min_y = pos.y; var max_y = pos.y
	for p in modules:
		min_x = min(min_x, p.x); max_x = max(max_x, p.x)
		min_y = min(min_y, p.y); max_y = max(max_y, p.y)
	
	if (max_x - min_x + 1) > MAX_SHIP_SIZE or (max_y - min_y + 1) > MAX_SHIP_SIZE:
		return false

	for n in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		if modules.has(pos + n): return true
	return false

func _on_build_requested(type: int, pos: Vector2i):
	var cost = 0
	match type:
		4: cost = hull_stats.cost
		2: cost = cargo_stats.cost
		3: cost = collector_stats.cost
	
	if type == 4: # HULL
		if can_expand_to(pos) and ResourceManager.spend_metal(cost):
			add_module(pos, type)
	else: # Build on HULL
		if modules.get(pos) == 4 and ResourceManager.spend_metal(cost):
			add_module(pos, type)

func get_module_at(pos: Vector2i) -> int:
	return modules.get(pos, 0)

func is_near_collector(grid_pos: Vector2i) -> bool:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if modules.get(grid_pos + Vector2i(dx, dy)) == 3: # COLLECTOR
				return true
	return false
