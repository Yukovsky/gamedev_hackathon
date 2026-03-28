extends Node
# Автозагрузка: SaveManager

const save_time_seconds = 60.0
const SAVE_PATH = "user://universal_save.json"

func _ready() -> void:
	var autosave_timer = Timer.new()
	autosave_timer.wait_time = save_time_seconds
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(save_game) 
	add_child(autosave_timer)

func save_game() -> void:
	var save_dict = {
		"resources": {
			"metal": ResourceManager.metal,
			"max_metal": ResourceManager.max_metal
		},
		"grid": _serialize_grid(GridTileManager.grid)
	}
	var json_string = JSON.stringify(save_dict)
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		print("Игра успешно сохранена!")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	var save_dict = JSON.parse_string(json_string)
	
	if save_dict:
		var res_data = save_dict.get("resources", {})
		ResourceManager.metal = res_data.get("metal", 0)
		ResourceManager.max_metal = res_data.get("max_metal", 50)
		
		GameEvents.resource_changed.emit("metal", ResourceManager.metal, ResourceManager.max_metal)
		
		var grid_data = save_dict.get("grid", {})
		GridTileManager.grid = _deserialize_grid(grid_data)
		print("Игра загружена!")

func _serialize_grid(grid: Dictionary) -> Dictionary:
	var string_grid = {}
	for pos in grid:
		var pos_str = str(pos.x) + "," + str(pos.y)
		string_grid[pos_str] = grid[pos]
	return string_grid

func _deserialize_grid(string_grid: Dictionary) -> Dictionary:
	var grid = {}
	for pos_str in string_grid:
		var parts = pos_str.split(",")
		if parts.size() == 2:
			var pos = Vector2i(int(parts[0]), int(parts[1]))
			grid[pos] = string_grid[pos_str]
	return grid
