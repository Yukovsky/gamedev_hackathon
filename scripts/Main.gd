extends Node2D

@onready var ship_container = $ShipContainer
@onready var junk_container = $JunkContainer
@onready var ui = $UI
@onready var build_overlay = $OverlayLayer/BuildOverlay
@onready var build_label = $OverlayLayer/BuildOverlay/Label
@onready var camera = $Camera2D

var ship_module_scene = preload("res://scenes/ShipModule.tscn")
var junk_scene = preload("res://scenes/Junk.tscn")

var building_type = 0 # GameManager.ModuleType

var zoom_speed = 0.1
var min_zoom = 0.5
var max_zoom = 2.0
var is_dragging = false
var last_drag_pos = Vector2()

func _ready():
	GameManager.ship_updated.connect(_update_ship_visuals)
	_update_ship_visuals()
	
	ui.build_mode_selected.connect(_on_ui_build_mode_selected)
	
	$JunkTimer.start()

func _update_ship_visuals():
	for child in ship_container.get_children():
		child.queue_free()
	
	for pos in GameManager.ship_modules:
		var type = GameManager.ship_modules[pos]
		var inst = ship_module_scene.instantiate()
		ship_container.add_child(inst)
		inst.setup(pos, type)

func _spawn_junk():
	if junk_container.get_child_count() < GameManager.MAX_JUNK:
		var inst = junk_scene.instantiate()
		junk_container.add_child(inst)

func _on_ui_build_mode_selected(type):
	building_type = type
	build_overlay.visible = true
	match type:
		4: build_label.text = "SELECT CELL TO EXPAND"
		2: build_label.text = "SELECT HULL TO BUILD CARGO"
		3: build_label.text = "SELECT HULL TO BUILD COLLECTOR"

func _input(event):
	# Handle Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom += Vector2(zoom_speed, zoom_speed)
			camera.zoom = camera.zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom -= Vector2(zoom_speed, zoom_speed)
			camera.zoom = camera.zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
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

	elif event is InputEventPanGesture:
		camera.zoom -= event.delta * zoom_speed
		camera.zoom = camera.zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

	if building_type == 0: return
	
	var is_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		# Need to make sure we are not clicking the UI.
		# Since UI and BuildOverlay are CanvasLayers, event.position is screen space
		if event.position.y < 180 or event.position.y > 2220:
			return
			
		var global_pos = get_global_mouse_position()
		var grid_pos = Vector2i(global_pos / 90)
		if GameManager.build_module(grid_pos, building_type):
			building_type = 0
			build_overlay.visible = false

func _on_junk_timer_timeout():
	_spawn_junk()

func _on_cancel_build_pressed():
	building_type = 0
	build_overlay.visible = false

