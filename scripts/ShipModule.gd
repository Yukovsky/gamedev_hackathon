extends Node2D

var grid_pos: Vector2i
var type = 0 # GameManager.ModuleType

@onready var label = $Label

var base_color: Color
var border_color: Color

func setup(p_pos: Vector2i, p_type: int):
	grid_pos = p_pos
	type = p_type
	position = Vector2(grid_pos) * 90 + Vector2(45, 45)
	
	match type:
		1: # CORE
			base_color = Color("3a6ea5") # Softer blue
			border_color = Color("1e3d5f")
			label.text = "CORE"
		2: # CARGO
			base_color = Color("c07c41") # Richer orange/brown
			border_color = Color("683a15")
			label.text = "CARGO"
		3: # COLLECTOR
			base_color = Color("2d936c") # Emerald green
			border_color = Color("144c36")
			label.text = "COLLECT"
		4: # HULL
			base_color = Color("4b5563") # Tech gray
			border_color = Color("1f2937")
			label.text = "HULL"
			
	queue_redraw()

func _draw():
	# Size is 90x90. Centered at 0,0, so rect is from -45 to +45.
	# Let's draw a nice rounded rect with a border.
	# We leave a 2px gap so modules look distinct.
	
	var rect = Rect2(-43, -43, 86, 86)
	var corner_radius = 8.0
	
	# Draw outer border (shadow/depth)
	draw_rect(rect, border_color, true)
	
	# Draw inner fill
	var inner_rect = Rect2(-41, -41, 82, 82)
	draw_rect(inner_rect, base_color, true)
	
	# Draw some "tech" lines or greebles
	var highlight_color = base_color.lightened(0.2)
	draw_line(Vector2(-35, -35), Vector2(-15, -35), highlight_color, 2.0)
	draw_line(Vector2(-35, -35), Vector2(-35, -15), highlight_color, 2.0)
	
	draw_line(Vector2(35, 35), Vector2(15, 35), border_color, 2.0)
	draw_line(Vector2(35, 35), Vector2(35, 15), border_color, 2.0)
