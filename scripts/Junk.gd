extends Area2D

var speed = 180.0
var collected = false
var rotation_speed = 0.0
var shape_points = []

func _ready():
	# Random spawn in grid cols (0 to 11), above the screen
	var col = randi_range(0, 11)
	position = Vector2(col * 90 + 45, -100)
	rotation_speed = randf_range(-2.0, 2.0)
	
	# Generate a random polygon shape for the debris
	var num_points = randi_range(5, 8)
	var radius = 25.0
	for i in range(num_points):
		var angle = (i / float(num_points)) * TAU
		var r = radius * randf_range(0.7, 1.3)
		shape_points.append(Vector2(cos(angle), sin(angle)) * r)
	
	queue_redraw()

func _process(delta):
	position.y += speed * delta
	rotation += rotation_speed * delta
	if position.y > 2500:
		queue_free()
	
	check_auto_collect()

func _draw():
	if shape_points.is_empty(): return
	# Draw the custom rock shape
	draw_colored_polygon(PackedVector2Array(shape_points), Color("8a8a8a"))
	
	# Draw border
	var border_points = shape_points.duplicate()
	border_points.append(shape_points[0]) # Close the loop
	draw_polyline(PackedVector2Array(border_points), Color("4a4a4a"), 2.0)

func check_auto_collect():
	if collected: return
	
	# Center position in grid coords
	var gx = int(position.x / 90)
	var gy = int(position.y / 90)
	var grid_pos = Vector2i(gx, gy)
	
	# Collectors check 1 cell radius
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var check_p = grid_pos + Vector2i(dx, dy)
			# ModuleType.COLLECTOR is 3
			if GameManager.get_module_at(check_p) == 3:
				collect()
				return

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		collect()
	elif event is InputEventScreenTouch and event.pressed:
		collect()

func collect():
	if collected: return
	collected = true
	GameManager.collect_junk()
	queue_free()

