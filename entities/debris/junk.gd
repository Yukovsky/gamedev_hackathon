extends Area2D

var speed = 180.0
var collected = false
var rotation_speed = 0.0

@onready var sprite = $Sprite2D

var textures = [
	preload("res://assets/space-shooter/meteorBrown_big1.png"),
	preload("res://assets/space-shooter/meteorBrown_big2.png"),
	preload("res://assets/space-shooter/meteorBrown_med1.png"),
	preload("res://assets/space-shooter/meteorBrown_med3.png"),
	preload("res://assets/space-shooter/meteorBrown_small1.png"),
	preload("res://assets/space-shooter/meteorBrown_small2.png"),
	preload("res://assets/space-shooter/meteorBrown_tiny1.png")
]

var ship_grid: Node2D = null

func _ready():
	var col = randi_range(0, 11)
	position = Vector2(col * 90 + 45, -100)
	rotation_speed = randf_range(-2.0, 2.0)
	sprite.texture = textures.pick_random()
	# Cache ship_grid
	ship_grid = get_tree().current_scene.find_child("ShipGrid", true, false)

func _process(delta):
	position.y += speed * delta
	rotation += rotation_speed * delta
	if position.y > 2500:
		queue_free()
	
	check_auto_collect()

func check_auto_collect():
	if collected or not is_instance_valid(ship_grid): return
	
	# Important: use local coordinates of ship_grid or global position
	# ShipGrid floats, so we check global distance to modules
	var grid_pos = Vector2i((global_position - ship_grid.global_position) / 90)
	
	if ship_grid.is_near_collector(grid_pos):
		collect()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		collect()
	elif event is InputEventScreenTouch and event.pressed:
		collect()

func collect():
	if collected: return
	collected = true
	GameEvents.metal_collected.emit(1)
	queue_free()
