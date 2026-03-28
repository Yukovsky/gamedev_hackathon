extends Node2D

@onready var ship_grid = $ShipGrid
@onready var junk_container = $JunkContainer
@onready var hud = $HUD
@onready var build_overlay = $OverlayLayer/BuildOverlay
@onready var build_label = $OverlayLayer/BuildOverlay/Label
@onready var camera = $Camera2D
@onready var background = $Background

var junk_scene = preload("res://entities/debris/junk.tscn")

var building_type = 0 
var zoom_speed = 0.1
var min_zoom = 0.4
var max_zoom = 2.5
var target_zoom = Vector2(1, 1)

var is_dragging = false
var last_drag_pos = Vector2()

# Floating effect variables
var float_time = 0.0
var float_amplitude = 15.0
var float_frequency = 0.5

func _ready():
	hud.build_mode_selected.connect(_on_ui_build_mode_selected)
	$JunkTimer.start()
	if camera:
		target_zoom = camera.zoom
	else:
		target_zoom = Vector2(1, 1)

func _process(delta):
	# Smooth Zoom interpolation
	if camera:
		camera.zoom = camera.zoom.lerp(target_zoom, 10 * delta)
	
	# Floating effect (drift)
	float_time += delta
	var float_offset = Vector2(
		sin(float_time * float_frequency) * float_amplitude,
		cos(float_time * float_frequency * 0.7) * float_amplitude
	)
	
	ship_grid.position = float_offset
	junk_container.position = float_offset * 0.5 # Parallax effect for junk
	
	# Parallax for background
	background.position = camera.position * 0.9 - Vector2(5000, 5000)

func _spawn_junk():
	if junk_container.get_child_count() < 5:
		var inst = junk_scene.instantiate()
		junk_container.add_child(inst)

func _on_ui_build_mode_selected(type):
	building_type = type
	build_overlay.visible = true
	match type:
		4: build_label.text = "ВЫБЕРИТЕ КЛЕТКУ ДЛЯ РАСШИРЕНИЯ"
		2: build_label.text = "ВЫБЕРИТЕ КОРПУС ДЛЯ СКЛАДА"
		3: build_label.text = "ВЫБЕРИТЕ КОРПУС ДЛЯ СБОРЩИКА"

func _unhandled_input(event):
	# Handle Zoom with Wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom *= (1.0 + zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom *= (1.0 - zoom_speed)
		
		target_zoom = target_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		
		# Dragging
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_dragging = true
				last_drag_pos = event.position
			else:
				is_dragging = false
				
	elif event is InputEventMouseMotion and is_dragging:
		var diff = event.position - last_drag_pos
		camera.position -= diff / camera.zoom
		last_drag_pos = event.position
		
	elif event is InputEventScreenDrag:
		camera.position -= event.relative / camera.zoom

	# Mobile gestures handled via standard events or ignored for now to ensure boot
	pass

	if building_type == 0: return
	
	var is_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		# Check if UI was clicked (approximate regions for Top and Bottom panels)
		if event.position.y < 250 or event.position.y > 2100:
			return
			
		var global_pos = get_global_mouse_position()
		# Compensate for ship_grid float_offset when calculating grid pos
		var grid_pos = Vector2i((global_pos - ship_grid.position) / 90)
		GameEvents.build_requested.emit(building_type, grid_pos)
		building_type = 0
		build_overlay.visible = false

func _on_junk_timer_timeout():
	_spawn_junk()

func _on_cancel_build_pressed():
	building_type = 0
	build_overlay.visible = false
