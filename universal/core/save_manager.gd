extends Node
# Автозагрузка: SaveManager

const save_time_seconds = 60.0
const SAVE_PATH = "user://universal_save.json"

var tutorial_flags: Dictionary = {}

func _ready() -> void:
	var autosave_timer = Timer.new()
	autosave_timer.wait_time = save_time_seconds
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(save_game) 
	add_child(autosave_timer)
	# Загружаем флаги туториалов при старте (они сохронены из предыдущих запусков)
	load_game()

func save_game() -> void:
	# Пытаемся найти GridManager в сцене, так как он теперь не Autoload
	var grid_manager = get_tree().root.find_child("GridManager", true, false)
	var grid_data = {}
	if grid_manager:
		grid_data = _serialize_grid(grid_manager.get_occupied_cells())

	var save_dict = {
		"resources": {
			"metal": ResourceManager.metal,
			"max_metal": ResourceManager.max_metal,
			"build_iterations_by_module": ResourceManager.build_iterations_by_module,
			"upgrade_levels": UpgradeManager.get_upgrade_levels_snapshot()
		},
		"tutorial": tutorial_flags.duplicate(true),
		"grid": grid_data
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
		var loaded_tutorial_flags: Dictionary = save_dict.get("tutorial", {})
		tutorial_flags = loaded_tutorial_flags.duplicate(true)

		var res_data = save_dict.get("resources", {})
		ResourceManager.metal = res_data.get("metal", 0)
		ResourceManager.max_metal = res_data.get("max_metal", 50)

		var loaded_iterations: Dictionary = res_data.get("build_iterations_by_module", {})
		if loaded_iterations.is_empty() and res_data.has("build_iteration"):
			var legacy_iteration: int = int(res_data.get("build_iteration", 0))
			loaded_iterations = {
				Constants.MODULE_REACTOR: legacy_iteration,
				Constants.MODULE_HULL: legacy_iteration,
				Constants.MODULE_COLLECTOR: legacy_iteration,
				Constants.MODULE_TURRET: legacy_iteration,
			}
		ResourceManager.set_module_build_iterations(loaded_iterations)

		var loaded_upgrade_levels: Dictionary = res_data.get("upgrade_levels", {})
		UpgradeManager.set_upgrade_levels(loaded_upgrade_levels)
		
		GameEvents.resource_changed.emit("metal", ResourceManager.metal)
		print("Игра загружена (ресурсы восстановлены)!")


func is_tutorial_shown(tutorial_id: String) -> bool:
	return bool(tutorial_flags.get(tutorial_id, false))


func mark_tutorial_shown(tutorial_id: String) -> void:
	if bool(tutorial_flags.get(tutorial_id, false)):
		return
	tutorial_flags[tutorial_id] = true
	save_game()

func _serialize_grid(grid: Dictionary) -> Dictionary:
	var string_grid = {}
	for pos in grid:
		var pos_str = str(pos.x) + "," + str(pos.y)
		# Сохраняем только тип модуля, если это возможно
		var entity = grid[pos]
		if entity and "module_id" in entity:
			string_grid[pos_str] = entity.module_id
		else:
			string_grid[pos_str] = "unknown"
	return string_grid

func _deserialize_grid(string_grid: Dictionary) -> Dictionary:
	var grid = {}
	for pos_str in string_grid:
		var parts = pos_str.split(",")
		if parts.size() == 2:
			var pos = Vector2i(int(parts[0]), int(parts[1]))
			grid[pos] = string_grid[pos_str]
	return grid
