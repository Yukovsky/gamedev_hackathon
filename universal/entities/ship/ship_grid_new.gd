extends Node2D

## Legacy compatibility stub.
## Active ship/grid logic is implemented in res://entities/game_board.gd and res://core/grid_manager.gd.

const CELL_SIZE: int = 90
const GRID_WIDTH: int = 12
const GRID_HEIGHT: int = 20


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos: Vector2 = to_local(world_pos)
	return Vector2i(
		int(floor(local_pos.x / float(CELL_SIZE))),
		int(floor(local_pos.y / float(CELL_SIZE)))
	)


func is_valid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < GRID_WIDTH and grid_pos.y >= 0 and grid_pos.y < GRID_HEIGHT
