extends RefCounted
class_name CoreUpgradeController
## Контроллер UI для плашки улучшения ядра.
## Управляет отображением уровня, стоимости и визуализацией прогресса.
## Отделён от MainUI для лучшей модульности.

const LEVEL_BAR_FILLED_COLOR: Color = Color(0.941, 0.816, 0.125, 1.0)
const COST_COLOR_NORMAL: Color = Color(0.941, 0.816, 0.125)
const COST_COLOR_INSUFFICIENT: Color = Color(0.8, 0.2, 0.2)
const PLAQUE_BORDER_READY_COLOR: Color = Color(0.247, 0.808, 0.847, 1.0)
const PLAQUE_BORDER_UNAVAILABLE_COLOR: Color = Color(0.392, 0.325, 0.475, 1.0)

var _core_cost_label: Label
var _core_level_label: Label
var _level_bars_container: HBoxContainer
var _core_plaque: PanelContainer
var _core_plaque_base_style: StyleBoxFlat
var _level_slot_base_styles: Array[StyleBoxFlat] = []


## Инициализирует контроллер с необходимыми UI-элементами.
func setup(
	core_cost_label: Label,
	core_level_label: Label,
	level_bars_container: HBoxContainer,
	core_plaque: PanelContainer
) -> void:
	_core_cost_label = core_cost_label
	_core_level_label = core_level_label
	_level_bars_container = level_bars_container
	_core_plaque = core_plaque
	_cache_core_plaque_style()
	_cache_level_slot_styles()


## Обновляет отображение информации о ядре.
func refresh(metal: int, upgrade_id: String) -> void:
	if upgrade_id.is_empty():
		return

	var level: int = UpgradeManager.get_upgrade_level(upgrade_id)
	var max_lvl: int = UpgradeManager.get_upgrade_max_level(upgrade_id)
	var cost: int = UpgradeManager.get_upgrade_next_cost(upgrade_id)

	_update_level_label(level, max_lvl)
	_update_cost_label(level, max_lvl, cost, metal)
	_update_core_plaque_style(level, max_lvl, cost, metal)
	_update_level_bars(level)


## Пытается выполнить улучшение ядра.
## Возвращает true, если улучшение успешно.
func try_purchase(upgrade_id: String) -> bool:
	if upgrade_id.is_empty():
		return false
	return UpgradeManager.purchase(upgrade_id)


func _update_level_label(level: int, max_lvl: int) -> void:
	if _core_level_label == null:
		return
	_core_level_label.text = "УРОВЕНЬ %d / %d" % [level, max_lvl]


func _update_cost_label(level: int, max_lvl: int, cost: int, metal: int) -> void:
	if _core_cost_label == null:
		return

	if level >= max_lvl:
		_core_cost_label.text = "MAX"
		_core_cost_label.add_theme_color_override("font_color", COST_COLOR_NORMAL)
	else:
		_core_cost_label.text = "%d •" % cost
		if metal < cost:
			_core_cost_label.add_theme_color_override("font_color", COST_COLOR_INSUFFICIENT)
		else:
			_core_cost_label.add_theme_color_override("font_color", COST_COLOR_NORMAL)


func _cache_level_slot_styles() -> void:
	_level_slot_base_styles.clear()
	if _level_bars_container == null:
		return

	for child in _level_bars_container.get_children():
		if child is Panel:
			var slot := child as Panel
			var style := slot.get_theme_stylebox("panel")
			if style is StyleBoxFlat:
				_level_slot_base_styles.append((style as StyleBoxFlat).duplicate())


func _cache_core_plaque_style() -> void:
	_core_plaque_base_style = null
	if _core_plaque == null:
		return

	var style := _core_plaque.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		_core_plaque_base_style = (style as StyleBoxFlat).duplicate()


func _update_core_plaque_style(level: int, max_lvl: int, cost: int, metal: int) -> void:
	if _core_plaque == null or _core_plaque_base_style == null:
		return

	var style: StyleBoxFlat = _core_plaque_base_style.duplicate()
	if level >= max_lvl:
		style.border_color = PLAQUE_BORDER_READY_COLOR
	elif metal >= cost:
		style.border_color = PLAQUE_BORDER_READY_COLOR
	else:
		style.border_color = PLAQUE_BORDER_UNAVAILABLE_COLOR

	_core_plaque.add_theme_stylebox_override("panel", style)


func _update_level_bars(level: int) -> void:
	if _level_bars_container == null:
		return

	for i in range(_level_bars_container.get_child_count()):
		var child := _level_bars_container.get_child(i)
		if not (child is Panel):
			continue

		var slot := child as Panel
		if i >= _level_slot_base_styles.size():
			continue

		var style := (_level_slot_base_styles[i] as StyleBoxFlat).duplicate()
		if i < level:
			style.bg_color = LEVEL_BAR_FILLED_COLOR
		slot.add_theme_stylebox_override("panel", style)
