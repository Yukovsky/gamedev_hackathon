extends Node2D

var grid_pos: Vector2i
var type = 0 

@onready var sprite = $Sprite2D
@onready var label = $Label

var core_tex = preload("res://assets/space-shooter/playerShip1_orange.png")
var cargo_tex = preload("res://assets/textures/cargo_new.png")
var collect_tex = preload("res://assets/space-shooter/laserRed16.png")

func setup(p_pos: Vector2i, p_type: int):
	grid_pos = p_pos
	type = p_type
	position = Vector2(grid_pos) * 90 + Vector2(45, 45)
	
	match type:
		1: # CORE
			sprite.texture = core_tex
			sprite.modulate = Color(1, 1, 1)
			sprite.scale = Vector2(0.8, 0.8)
		2: # CARGO
			sprite.texture = cargo_tex
			sprite.modulate = Color(1, 1, 1)
			sprite.scale = Vector2(0.15, 0.15)
		3: # COLLECTOR
			sprite.texture = collect_tex
			sprite.modulate = Color(0.4, 1, 0.6)
			sprite.scale = Vector2(1.5, 1.5)
			sprite.rotation = PI/2
		4: # HULL
			sprite.texture = null
			queue_redraw()

func _draw():
	if type == 4: # HULL
		var rect = Rect2(-43, -43, 86, 86)
		var border_color = Color("1f2937")
		var base_color = Color("4b5563")
		draw_rect(rect, border_color, true)
		var inner_rect = Rect2(-41, -41, 82, 82)
		draw_rect(inner_rect, base_color, true)
