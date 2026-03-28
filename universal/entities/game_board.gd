extends Node2D

const CELL_SIZE = 120 
const START_X = 1080 / 2 - CELL_SIZE
const START_Y = 2400 - (CELL_SIZE * 5) 

func _ready() -> void:
	print("GameBoard Initialized")
	_draw_base_ship()
	GameEvents.build_requested.connect(_on_build_requested)

func _draw_base_ship() -> void:
	# Базовый корабль занимает зону 2x3
	var layout = [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(1, 1),
		Vector2i(0, 2), Vector2i(1, 2)
	]
	
	for pos in layout:
		_add_hull_tile(pos)

func _add_hull_tile(grid_pos: Vector2i) -> void:
	var rect = ColorRect.new()
	rect.color = Color(0.2, 0.6, 0.8) 
	rect.size = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
	rect.position = Vector2(START_X + grid_pos.x * CELL_SIZE, START_Y + grid_pos.y * CELL_SIZE)
	add_child(rect)
	
	# Добавляем в менеджер сетки
	if GridTileManager:
		GridTileManager.set_cell(grid_pos, rect)
	
	# Визуальный номер для отладки
	var label = Label.new()
	label.text = str(grid_pos.x) + "," + str(grid_pos.y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.add_child(label)

func _on_build_requested(type: String, _pos: Vector2) -> void:
	if type == "hull":
		# Находим свободное место рядом с существующими клетками
		var new_pos = _find_free_adjacent_pos()
		if new_pos != Vector2i(-99,-99):
			_add_hull_tile(new_pos)
			print("Built Hull at ", new_pos)
	elif type == "generator":
		print("Generator visually built (Logic: max metal increased)")
	elif type == "collector":
		print("Collector visually built")

func _find_free_adjacent_pos() -> Vector2i:
	if not GridTileManager: return Vector2i(-99,-99)
	
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	var occupied = GridTileManager.grid.keys()
	
	for pos in occupied:
		for dir in directions:
			var candidate = pos + dir
			if not GridTileManager.grid.has(candidate):
				return candidate
	return Vector2i(-99,-99)
