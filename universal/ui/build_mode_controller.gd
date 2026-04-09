extends Node
## Контроллер режима строительства.
## Управляет переключением верхних панелей и отображением характеристик выбранного модуля.

var _top_panel_normal: Node
var _top_panel_build: Node
var _is_build_mode: bool = false
var _previous_screen: int = 2

func _ready() -> void:
	# Находим верхние панели в сцене
	_top_panel_normal = get_tree().root.get_child(0).find_child("TopPanel", true, false)
	_top_panel_build = get_tree().root.get_child(0).find_child("BuildModeTopPanel", true, false)
	
	if _top_panel_build:
		_top_panel_build.hide()
	
	# Подключаемся к сигналам игры
	GameEvents.build_mode_changed.connect(_on_build_mode_changed)
	GameEvents.build_mode_cancelled.connect(_on_build_mode_cancelled)

func _on_build_mode_changed(module_type: String) -> void:
	"""Переключаемся в режим строительства и показываем характеристики модуля."""
	if _is_build_mode:
		return
	
	_is_build_mode = true
	
	# Сохраняем текущий экран
	var main_ui = get_tree().root.get_child(0)
	if main_ui.has_meta("_current_screen"):
		_previous_screen = main_ui.get_meta("_current_screen")
	
	# Скрываем нормальную панель, показываем панель строительства
	if _top_panel_normal:
		_top_panel_normal.hide()
	
	if _top_panel_build:
		_top_panel_build.show()
		_update_build_panel(module_type)

func _on_build_mode_cancelled() -> void:
	"""Выходим из режима строительства и возвращаемся на предыдущий экран."""
	if not _is_build_mode:
		return
	
	_is_build_mode = false
	
	# Показываем нормальную панель, скрываем панель строительства
	if _top_panel_normal:
		_top_panel_normal.show()
	
	if _top_panel_build:
		_top_panel_build.hide()
	
	# Возвращаемся на предыдущий экран
	var main_ui = get_tree().root.get_child(0)
	if main_ui.has_method("_set_current_screen"):
		main_ui._set_current_screen(_previous_screen)

func _update_build_panel(module_type: String) -> void:
	"""Обновляет информацию на панели строительства в зависимости от типа модуля."""
	if not _top_panel_build:
		return
	
	var stat_label = _top_panel_build.find_child("StatLabel", true, false)
	var stat_value = _top_panel_build.find_child("StatValue", true, false)
	
	if not stat_label or not stat_value:
		return
	
	match module_type:
		Constants.MODULE_COLLECTOR:
			stat_label.text = "Металл/сек +"
			# Fallback values for collector production
			var metal_per_sec = 5  # Default value
			stat_value.text = str(metal_per_sec)
			stat_value.modulate.a = 1.0
		
		Constants.MODULE_TURRET:
			stat_label.text = "Урон/сек +"
			# Fallback values for turret damage
			var damage_per_sec = 15  # Default value
			stat_value.text = str(damage_per_sec)
			stat_value.modulate.a = 1.0
		
		Constants.MODULE_HULL:
			stat_label.text = "Металл макс +"
			var hull_bonus = Constants.get_hull_metal_bonus()
			stat_value.text = str(hull_bonus)
			stat_value.modulate.a = 1.0
		
		Constants.MODULE_REACTOR:
			stat_label.text = "Энергия +"
			# Fallback values for reactor energy
			var energy_bonus = 50  # Default value
			stat_value.text = str(energy_bonus)
			stat_value.modulate.a = 1.0
		
		_:
			stat_label.text = "Характеристика"
			stat_value.text = "?"
