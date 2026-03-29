extends CanvasLayer

@onready var metal_label: Label = %MetalLabel
@onready var metal_counter: Label = %MetalCounter
@onready var metal_bar: TextureProgressBar = %MetalBar
@onready var shop_metal_label: Label = %ShopMetalLabel
@onready var shop_metal_counter: Label = %ShopMetalCounter
@onready var shop_metal_bar: TextureProgressBar = %ShopMetalBar
@onready var btn_reactor: Button = %BtnReactor
@onready var btn_collector: Button = %BtnCollector
@onready var btn_hull: Button = %BtnHull
@onready var btn_turret: Button = %BtnTurret
@onready var btn_shop: Button = %BtnShop
@onready var btn_shop_exit: Button = %BtnShopExit
@onready var shop_overlay: ColorRect = %ShopOverlay
@onready var end_overlay: ColorRect = %EndOverlay
@onready var end_title_label: Label = %EndTitleLabel
@onready var end_reason_label: Label = %EndReasonLabel
@onready var btn_restart: Button = %BtnRestart

# Новые элементы Ядра
@onready var core_cost_label: Label = %CoreCost
@onready var core_level_label: Label = %CoreLevelLabel
@onready var core_upgrade_btn: Button = %CoreUpgradeBtn # Мы можем использовать невидимую кнопку или просто клик по плашке
@onready var level_bars_container: HBoxContainer = %LevelBars
@onready var core_plaque: PanelContainer = %CorePlaque

var _is_game_finished: bool = false
var _shop_open: bool = false
var _level_slot_base_styles: Array[StyleBoxFlat] = []
var _tutorial_target_controls: Dictionary = {}
var _tutorial_focused_control: Control
var _tutorial_focus_tween: Tween
var _tutorial_focus_color: Color = Color.WHITE

const LEVEL_BAR_FILLED_COLOR: Color = Color(0.941, 0.816, 0.125, 1.0)
const TUTORIAL_FOCUS_PULSE: Color = Color(6.5, 6.5, 6.5, 1.0)  # Экстра-яркий пик поверх затемнения
const TUTORIAL_FOCUS_BASE_BOOST: float = 2.2  # Минимум пульса тоже яркий

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.module_built.connect(_on_module_built)
	GameEvents.build_mode_cancelled.connect(_on_build_mode_cancelled)
	if GameEvents.has_signal("game_finished"):
		GameEvents.game_finished.connect(_on_game_finished)
	GameEvents.upgrade_purchased.connect(_on_upgrade_purchased)
	GameEvents.tutorial_focus_changed.connect(_on_tutorial_focus_changed)
	GameEvents.tutorial_focus_cleared.connect(_on_tutorial_focus_cleared)
	GameEvents.tutorial_action_requested.connect(_on_tutorial_action_requested)

	btn_reactor.pressed.connect(_on_btn_reactor_pressed)
	btn_collector.pressed.connect(_on_btn_collector_pressed)
	btn_hull.pressed.connect(_on_btn_hull_pressed)
	btn_turret.pressed.connect(_on_btn_turret_pressed)
	btn_shop.pressed.connect(_on_btn_shop_pressed)
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	btn_shop_exit.pressed.connect(_on_btn_shop_exit_pressed)

	# Клик по плашке ядра для апгрейда: дочерние элементы не перехватывают нажатие.
	core_plaque.mouse_filter = Control.MOUSE_FILTER_STOP
	_make_children_mouse_passthrough(core_plaque)
	core_plaque.gui_input.connect(_on_core_plaque_input)

	_cache_level_slot_styles()
	_register_tutorial_targets()

	_refresh_ui()
	_set_shop_open(false, false)
	end_overlay.visible = false

func _process(_delta: float) -> void:
	if _tutorial_focused_control == null:
		return
	if not is_instance_valid(_tutorial_focused_control):
		return
	if not _tutorial_focused_control.visible:
		return
	GameEvents.tutorial_target_rect_changed.emit(_get_focused_target_id(), _tutorial_focused_control.get_global_rect())

func _on_resource_changed(type: String, _new_total: int) -> void:
	if type == "metal":
		_refresh_ui()

func _refresh_ui() -> void:
	var metal = ResourceManager.metal
	var max_metal = ResourceManager.max_metal
	metal_label.text = "МЕТАЛЛ"
	metal_counter.text = "%d / %d" % [metal, max_metal]
	shop_metal_label.text = "МЕТАЛЛ"
	shop_metal_counter.text = "%d / %d" % [metal, max_metal]
	
	if metal_bar:
		metal_bar.max_value = max_metal
		metal_bar.value = metal
	if shop_metal_bar:
		shop_metal_bar.max_value = max_metal
		shop_metal_bar.value = metal

	# Обновление цен на кнопках модулей
	_update_module_button(btn_hull, Constants.MODULE_HULL, metal)
	_update_module_button(btn_reactor, Constants.MODULE_REACTOR, metal)
	_update_module_button(btn_collector, Constants.MODULE_COLLECTOR, metal)
	_update_module_button(btn_turret, Constants.MODULE_TURRET, metal)

	# Обновление ядра
	_refresh_core_info(metal)

func _update_module_button(btn: Button, type: String, metal: int) -> void:
	var cost = ResourceManager.get_current_module_cost(type)
	var price_label = btn.get_node("V/Price")
	price_label.text = "%d +" % cost
	btn.disabled = metal < cost

	if btn.disabled:
		price_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	else:
		price_label.add_theme_color_override("font_color", Color(0.941, 0.816, 0.125))

func _refresh_core_info(metal: int) -> void:
	var upgrade_id = _get_active_upgrade_id()
	if upgrade_id.is_empty():
		return

	var level = UpgradeManager.get_upgrade_level(upgrade_id)
	var max_lvl = UpgradeManager.get_upgrade_max_level(upgrade_id)
	var cost = UpgradeManager.get_upgrade_next_cost(upgrade_id)

	core_level_label.text = "УРОВЕНЬ %d / %d" % [level, max_lvl]

	if level >= max_lvl:
		core_cost_label.text = "MAX"
	else:
		core_cost_label.text = "%d •" % cost
		if metal < cost:
			core_cost_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
		else:
			core_cost_label.add_theme_color_override("font_color", Color(0.941, 0.816, 0.125))

	_update_level_bars(level)

func _on_core_plaque_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var upgrade_id = _get_active_upgrade_id()
		if upgrade_id.is_empty():
			return
		if UpgradeManager.purchase(upgrade_id):
			AudioManager.play_ui_click()
			_refresh_ui()

func _on_btn_shop_pressed() -> void:
	if _is_game_finished: return
	AudioManager.play_ui_open()
	_set_shop_open(not _shop_open, true)

func _set_shop_open(value: bool, sync_pause: bool) -> void:
	_shop_open = value
	shop_overlay.visible = value
	if sync_pause:
		get_tree().paused = value

	if value:
		GameEvents.shop_opened.emit()
	else:
		GameEvents.shop_closed.emit()

func _on_btn_shop_exit_pressed() -> void:
	AudioManager.play_ui_click()
	_set_shop_open(false, true)

func _on_module_built(_type: String, _pos: Vector2) -> void:
	_set_shop_open(false, true)
	_refresh_ui()

func _on_build_mode_cancelled(_type: String) -> void:
	if _is_game_finished:
		return
	_set_shop_open(false, true)
	_refresh_ui()

func _on_upgrade_purchased(_id: String, _lvl: int) -> void:
	_refresh_ui()

func _get_active_upgrade_id() -> String:
	if UpgradeManager.get_upgrade_ids().has(Constants.UPGRADE_CORE_ID):
		return Constants.UPGRADE_CORE_ID

	var upgrade_ids: Array[String] = UpgradeManager.get_upgrade_ids()
	if upgrade_ids.is_empty():
		return ""
	return upgrade_ids[0]

func _make_children_mouse_passthrough(parent: Control) -> void:
	for child in parent.get_children():
		if child is Control:
			var child_control := child as Control
			child_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_make_children_mouse_passthrough(child_control)

func _cache_level_slot_styles() -> void:
	_level_slot_base_styles.clear()
	for child in level_bars_container.get_children():
		if child is Panel:
			var slot := child as Panel
			var style := slot.get_theme_stylebox("panel")
			if style is StyleBoxFlat:
				_level_slot_base_styles.append((style as StyleBoxFlat).duplicate())

func _update_level_bars(level: int) -> void:
	for i in range(level_bars_container.get_child_count()):
		var child := level_bars_container.get_child(i)
		if not (child is Panel):
			continue

		var slot := child as Panel
		if i >= _level_slot_base_styles.size():
			continue

		var style := (_level_slot_base_styles[i] as StyleBoxFlat).duplicate()
		if i < level:
			style.bg_color = LEVEL_BAR_FILLED_COLOR
		slot.add_theme_stylebox_override("panel", style)

func _on_btn_hull_pressed() -> void: _request_build(Constants.MODULE_HULL)
func _on_btn_reactor_pressed() -> void: _request_build(Constants.MODULE_REACTOR)
func _on_btn_collector_pressed() -> void: _request_build(Constants.MODULE_COLLECTOR)
func _on_btn_turret_pressed() -> void: _request_build(Constants.MODULE_TURRET)

func _request_build(type: String) -> void:
	if _is_game_finished: return
	AudioManager.play_ui_click()
	GameEvents.build_requested.emit(type, Vector2.ZERO)
	_set_shop_open(false, false) # Закрываем для выбора места

func _on_game_finished(outcome: String, reason: String) -> void:
	_is_game_finished = true
	_set_shop_open(false, false)
	get_tree().paused = true
	end_overlay.visible = true
	if outcome == "win":
		end_title_label.text = "ПОБЕДА"
		end_reason_label.text = "Миссия выполнена!"
	else:
		end_title_label.text = "GAME OVER"
		end_reason_label.text = "Ядро уничтожено."

func _on_btn_restart_pressed() -> void:
	get_tree().paused = false
	if ResourceManager.has_method("reset"): ResourceManager.reset()
	if UpgradeManager.has_method("reset"): UpgradeManager.reset()
	get_tree().reload_current_scene()

func _register_tutorial_targets() -> void:
	_tutorial_target_controls = {
		"shop_button": btn_shop,
		"hull": btn_hull,
		"reactor": btn_reactor,
		"collector": btn_collector,
		"turret": btn_turret,
		"core": core_plaque,
	}

func _on_tutorial_focus_changed(target_id: String, accent_color: Color, _allow_interaction: bool) -> void:
	_on_tutorial_focus_cleared()
	if not _tutorial_target_controls.has(target_id):
		return

	var target = _tutorial_target_controls[target_id]
	if not (target is Control):
		return

	_tutorial_focused_control = target as Control
	_tutorial_focus_color = accent_color
	if not _tutorial_focused_control.visible:
		return

	var boosted_focus_color := Color(
		_tutorial_focus_color.r * TUTORIAL_FOCUS_BASE_BOOST,
		_tutorial_focus_color.g * TUTORIAL_FOCUS_BASE_BOOST,
		_tutorial_focus_color.b * TUTORIAL_FOCUS_BASE_BOOST,
		1.0
	)

	_tutorial_focused_control.modulate = boosted_focus_color
	_tutorial_focus_tween = create_tween()
	_tutorial_focus_tween.set_loops()
	_tutorial_focus_tween.set_trans(Tween.TRANS_SINE)
	_tutorial_focus_tween.set_ease(Tween.EASE_IN_OUT)
	_tutorial_focus_tween.tween_property(_tutorial_focused_control, "modulate", TUTORIAL_FOCUS_PULSE, 0.3)
	_tutorial_focus_tween.tween_property(_tutorial_focused_control, "modulate", boosted_focus_color, 0.3)

	GameEvents.tutorial_target_rect_changed.emit(target_id, _tutorial_focused_control.get_global_rect())

func _on_tutorial_focus_cleared() -> void:
	if _tutorial_focus_tween:
		_tutorial_focus_tween.kill()
		_tutorial_focus_tween = null
	if _tutorial_focused_control and is_instance_valid(_tutorial_focused_control):
		_tutorial_focused_control.modulate = Color.WHITE
	_tutorial_focused_control = null

func _on_tutorial_action_requested(action_id: String) -> void:
	match action_id:
		"open_shop":
			if not _shop_open:
				_on_btn_shop_pressed()
		"buy_hull":
			if _shop_open and not btn_hull.disabled:
				_on_btn_hull_pressed()

func _get_focused_target_id() -> String:
	for id in _tutorial_target_controls.keys():
		if _tutorial_target_controls[id] == _tutorial_focused_control:
			return str(id)
	return ""
