extends Node
# Автозагрузка: SaveManager

const save_time_seconds = 60.0
const SAVE_PATH = "user://universal_save.json"

func _ready() -> void:
	# 1. Настройка автосохранения по таймеру
	var autosave_timer = Timer.new()
	autosave_timer.wait_time = save_time_seconds # Сохранять каждые 60 секунд
	autosave_timer.autostart = true
	# Подключаем сигнал окончания таймера к функции сохранения
	autosave_timer.timeout.connect(save_game) 
	add_child(autosave_timer)

# ==========================================
# Логика сохранения
# ==========================================
func save_game() -> void:
	# Собираем данные со всех систем
	var save_dict = {
		"resources": {
			"metal": ResourceManager.metal,
			"energy": ResourceManager.energy
		},
		# JSON требует, чтобы ключи словаря были строками.
		# Поэтому мы преобразуем ключи Vector2i из GridManager в строки.
		"grid": _serialize_grid(GridTileManager.grid)
	}
	# Превращаем словарь в строку JSON
	var json_string = JSON.stringify(save_dict)
	
	# Открываем файл на запись и сохраняем
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		print("Игра успешно сохранена!")
	else:
		push_error("Не удалось открыть файл для сохранения.")

# ==========================================
# Логика загрузки
# ==========================================
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("Файл сохранения не найден. Начинаем новую игру.")
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	
	# Парсим JSON обратно в словарь
	var save_dict = JSON.parse_string(json_string)
	
	if save_dict:
		# 1. Восстанавливаем ресурсы
		var res_data = save_dict.get("resources", {})
		ResourceManager.metal = res_data.get("metal", 100) # 100 - значение по умолчанию
		ResourceManager.energy = res_data.get("energy", 0)
		
		# Оповещаем UI об изменениях через Event Bus!
		GameEvents.resource_changed.emit("metal", ResourceManager.metal)
		GameEvents.resource_changed.emit("energy", ResourceManager.energy)
		
		# 2. Восстанавливаем сетку
		var grid_data = save_dict.get("grid", {})
		GridTileManager.grid = _deserialize_grid(grid_data)
		
		for tile in GridTileManager.grid:
			#OCCUPY CELL
			print("Здесь должно быть заполнение клеток")
		# Здесь можно добавить вызов функции, которая заспавнит визуал комнат на основе GridManager.occupied_cells
		
		print("Игра загружена!")

# ==========================================
# Вспомогательные функции (Vector2i <-> String)
# ==========================================
func _serialize_grid(grid: Dictionary) -> Dictionary:
	var string_grid = {}
	for pos in grid:
		var pos_str = str(pos.x) + "," + str(pos.y) # Превращаем Vector2i(5, 10) в строку "5,10"
		string_grid[pos_str] = grid[pos]
	return string_grid

func _deserialize_grid(string_grid: Dictionary) -> Dictionary:
	var grid = {}
	for pos_str in string_grid:
		var parts = pos_str.split(",")
		if parts.size() == 2:
			var pos = Vector2i(parts.to_int(), parts.to_int())
			grid[pos] = string_grid[pos_str]
	return grid
