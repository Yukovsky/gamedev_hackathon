extends Node2D
class_name ModuleBase

@export var module_id: String = ""
@export var grid_size: Vector2i = Vector2i.ONE
@export var metal_cost: int = 0
@export var defence_bonus: int = 0
@export var energy_radius_cells: int = 0
@export var facing_direction: Vector2 = Vector2.UP
@export var sprite_color: Color = Color(0.55, 0.55, 0.55, 1.0)

var grid_position: Vector2i = Vector2i.ZERO
var cell_size_px: float = 90.0


func configure(cell_pos: Vector2i, cell_size: float) -> void:
	grid_position = cell_pos
	cell_size_px = cell_size
	position = Vector2(cell_pos.x * cell_size_px, cell_pos.y * cell_size_px)
	queue_redraw()


func get_occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(grid_position.x, grid_position.x + grid_size.x):
		for y in range(grid_position.y, grid_position.y + grid_size.y):
			result.append(Vector2i(x, y))
	return result


func get_world_center() -> Vector2:
	return global_position + Vector2(grid_size.x, grid_size.y) * cell_size_px * 0.5


func set_facing_direction(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()


func _draw() -> void:
	var size_px: Vector2 = Vector2(grid_size.x * cell_size_px, grid_size.y * cell_size_px)
	var fill_rect: Rect2 = Rect2(Vector2.ZERO, size_px)

	draw_rect(fill_rect, sprite_color, true)
	draw_rect(fill_rect, Color(0.08, 0.08, 0.08, 1.0), false, 2.0)
