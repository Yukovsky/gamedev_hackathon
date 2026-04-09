extends CanvasLayer
## Главный UI-контроллер игры — архитектура 5 экранов с навигацией по нижним кнопкам.
## Screen 0: Улучшения | Screen 1: Оборона | Screen 2: Игра | Screen 3: Автоматизация | Screen 4: Дерево (заблокирован).
## Магазинные экраны ставят игру на паузу; возврат на экран 2 снимает паузу.
## Взаимодействует с игрой через Event Bus (GameEvents).

const TutorialFocusControllerScript: Script = preload("res://ui/tutorial_focus_controller.gd")
const CoreUpgradeControllerScript: Script = preload("res://ui/core_upgrade_controller.gd")
const BuildModeTopPanelControllerScript: Script = preload("res://ui/build_mode_top_panel_controller.gd")

const SCREEN_SCENES: Dictionary = {
	0: "res://ui/screen_0_upgrades.tscn",
	1: "res://ui/screen_1_defense.tscn",
	3: "res://ui/screen_3_automation.tscn",
}

const SCREEN_COUNT: int = 5
const DEFAULT_SCREEN: int = 2

const NAV_ICONS: Array[String] = ["⬆", "🛡", "🚀", "⚡", "🔬"]
const NAV_ACTIVE_COLOR: Color = Color(0.4, 0.8, 1.0)
const NAV_INACTIVE_COLOR: Color = Color(0.5, 0.4, 0.6, 0.6)
const NAV_DISABLED_COLOR: Color = Color(0.3, 0.3, 0.3, 0.3)

@export var ui_base_margin_left: int = 24
@export var ui_base_margin_top: int = 24
@export var ui_base_margin_right: int = 24
@export var ui_base_margin_bottom: int = 24
const NAV_BAR_HEIGHT: int = 180
const NAV_CONTENT_GAP: int = 20

# --- Верхняя панель (Screen 2 HUD) ---
@onready var top_header: PanelContainer = %TopHeader
@onready var metal_label: Label = %MetalLabel
@onready var metal_counter: Label = %MetalCounter
@onready var metal_bar: TextureProgressBar = %MetalBar
@onready var metal_max_notice_stack: MetalMaxNoticeStack = %MetalMaxNoticeStack
@onready var btn_settings: Button = %BtnSettings

# --- Build Mode верхняя панель ---
@onready var build_mode_top_panel: PanelContainer = %BuildModeTopPanel
@onready var build_mode_stat_label: Label = %BuildModeStatLabel
@onready var build_mode_stat_value: Label = %BuildModeStatValue

# --- Экранный контейнер ---
@onready var screen_container: Control = %ScreenContainer
@onready var screen_dark_bg: ColorRect = %ScreenDarkBg
@onready var spacer: Control = %Spacer

# --- Нижняя панель навигации ---
@onready var bottom_nav_panel: PanelContainer = %BottomNavPanel
@onready var nav_buttons_container: HBoxContainer = %NavButtonsContainer

# --- Оверлеи ---
@onready var settings_overlay: Control = %SettingsOverlay
@onready var end_overlay: ColorRect = %EndOverlay
@onready var end_title_label: Label = %EndTitleLabel
@onready var end_reason_label: Label = %EndReasonLabel
@onready var btn_restart: Button = %BtnRestart
@onready var confirm_exit_overlay: ColorRect = %ConfirmExitOverlay
@onready var btn_confirm_exit_yes: Button = %BtnConfirmExitYes
@onready var btn_confirm_exit_no: Button = %BtnConfirmExitNo

@onready var root_margin_container: MarginContainer = $MarginContainer
@onready var end_center_container: Control = $EndOverlay/Center

var _current_screen: int = DEFAULT_SCREEN
var _previous_screen: int = DEFAULT_SCREEN
var _loaded_screens: Dictionary = {}
var _is_game_finished: bool = false
var _tutorial_focus: RefCounted
var _core_upgrade: RefCounted
var _build_mode_panel: RefCounted
var _first_raider_focus_target_registered: bool = false
var _nav_buttons: Array[Button] = []

# Build mode — запоминаем откуда зашли
var _pre_build_screen: int = DEFAULT_SCREEN
var _is_in_build_mode: bool = false
var _pending_build_type: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tutorial_focus = TutorialFocusControllerScript.new()
	_build_mode_panel = BuildModeTopPanelControllerScript.new()
	_build_mode_panel.setup(build_mode_top_panel, build_mode_stat_label, build_mode_stat_value)

	if metal_max_notice_stack != null:
		metal_max_notice_stack.set_notice_font(metal_label.get_theme_font("font"))

	_apply_safe_area()
	if not get_viewport().size_changed.is_connected(_apply_safe_area):
		get_viewport().size_changed.connect(_apply_safe_area)

	# Event Bus подписки
	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.resource_cap_reached.connect(_on_resource_cap_reached)
	GameEvents.build_requested.connect(_on_build_requested)
	GameEvents.module_built.connect(_on_module_built)
	GameEvents.build_mode_changed.connect(_on_build_mode_changed)
	GameEvents.build_mode_cancelled.connect(_on_build_mode_cancelled)
	if GameEvents.has_signal("game_finished"):
		GameEvents.game_finished.connect(_on_game_finished)
	GameEvents.upgrade_purchased.connect(_on_upgrade_purchased)
	GameEvents.tutorial_focus_changed.connect(_on_tutorial_focus_changed)
	GameEvents.tutorial_focus_cleared.connect(_on_tutorial_focus_cleared)
	GameEvents.tutorial_action_requested.connect(_on_tutorial_action_requested)
	GameEvents.raider_spawned.connect(_on_raider_spawned)
	GameEvents.raider_destroyed.connect(_on_raider_destroyed)

	# Кнопки оверлеев
	btn_settings.pressed.connect(_on_btn_settings_pressed)
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	btn_confirm_exit_yes.pressed.connect(_on_btn_confirm_exit_yes_pressed)
	btn_confirm_exit_no.pressed.connect(_on_btn_confirm_exit_no_pressed)

	_setup_nav_buttons()
	_register_tutorial_targets()

	end_overlay.visible = false
	_set_confirm_exit_visible(false)
	_switch_to_screen(DEFAULT_SCREEN, false)
	_refresh_hud()


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_apply_safe_area):
		get_viewport().size_changed.disconnect(_apply_safe_area)


func _apply_safe_area() -> void:
	var window_size: Vector2i = DisplayServer.window_get_size()
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	if safe_area.size.x <= 0 or safe_area.size.y <= 0:
		safe_area = Rect2i(Vector2i.ZERO, window_size)

	var safe_left: int = max(0, int(safe_area.position.x))
	var safe_top: int = max(0, int(safe_area.position.y))
	var safe_right: int = max(0, int(window_size.x - safe_area.end.x))
	var safe_bottom: int = max(0, int(window_size.y - safe_area.end.y))

	# Main content margins — bottom accounts for external nav bar + side/bottom gaps
	var content_bottom: int = NAV_BAR_HEIGHT + NAV_CONTENT_GAP + ui_base_margin_bottom + safe_bottom
	root_margin_container.add_theme_constant_override("margin_left", ui_base_margin_left + safe_left)
	root_margin_container.add_theme_constant_override("margin_top", ui_base_margin_top + safe_top)
	root_margin_container.add_theme_constant_override("margin_right", ui_base_margin_right + safe_right)
	root_margin_container.add_theme_constant_override("margin_bottom", content_bottom)

	# Bottom nav panel — inset on all 4 sides like TopHeader
	var nav_bottom_offset: int = ui_base_margin_bottom + safe_bottom
	bottom_nav_panel.offset_top = float(-(NAV_BAR_HEIGHT + nav_bottom_offset))
	bottom_nav_panel.offset_bottom = -float(nav_bottom_offset)
	bottom_nav_panel.offset_left = float(ui_base_margin_left + safe_left)
	bottom_nav_panel.offset_right = -float(ui_base_margin_right + safe_right)

	if end_center_container:
		end_center_container.offset_left = float(safe_left)
		end_center_container.offset_top = float(safe_top)
		end_center_container.offset_right = -float(safe_right)
		end_center_container.offset_bottom = -float(safe_bottom)


func _process(_delta: float) -> void:
	if _tutorial_focus != null:
		_tutorial_focus.process_focus_tracking()


# ========== Навигация между экранами ==========

func _setup_nav_buttons() -> void:
	_nav_buttons.clear()
	for i in range(SCREEN_COUNT):
		var btn: Button = nav_buttons_container.get_child(i) as Button
		if btn == null:
			continue
		_nav_buttons.append(btn)
		var idx: int = i
		if not btn.pressed.is_connected(_on_nav_button_pressed.bind(idx)):
			btn.pressed.connect(_on_nav_button_pressed.bind(idx))
	_update_nav_highlights()


func _on_nav_button_pressed(index: int) -> void:
	if index == 4:
		return # Дерево улучшений заблокировано
	if _is_in_build_mode:
		return
	_switch_to_screen(index)


func _switch_to_screen(index: int, should_emit: bool = true) -> void:
	if index < 0 or index >= SCREEN_COUNT:
		return
	if index == 4:
		return

	_previous_screen = _current_screen
	_current_screen = index

	_hide_all_loaded_screens()

	if index == 2:
		# Экран игры — нет загружаемого контента, только HUD
		top_header.visible = not _is_in_build_mode
		build_mode_top_panel.visible = _is_in_build_mode
		screen_dark_bg.visible = false
		spacer.visible = not _is_in_build_mode
		bottom_nav_panel.visible = not _is_in_build_mode
		if metal_max_notice_stack != null:
			metal_max_notice_stack.visible = not _is_in_build_mode
		# Снимаем паузу только если НЕ в режиме строительства
		if not _is_in_build_mode:
			get_tree().paused = false
	else:
		# Загружаем/показываем экран магазина — ставим игру на паузу
		_show_screen(index)
		top_header.visible = false
		build_mode_top_panel.visible = false
		screen_dark_bg.visible = true
		spacer.visible = false
		bottom_nav_panel.visible = true
		if metal_max_notice_stack != null:
			metal_max_notice_stack.visible = false
		get_tree().paused = true
		SaveManager.save_game()

	_update_nav_highlights()
	if should_emit:
		GameEvents.screen_changed.emit(index)
		if index != 2:
			GameEvents.shop_opened.emit()


func _show_screen(index: int) -> void:
	if not SCREEN_SCENES.has(index):
		return

	if not _loaded_screens.has(index):
		var scene: PackedScene = load(SCREEN_SCENES[index]) as PackedScene
		if scene == null:
			push_warning("Failed to load screen scene: %s" % SCREEN_SCENES[index])
			return
		var instance: Control = scene.instantiate() as Control
		instance.name = "Screen_%d" % index
		# Работают даже при паузе (магазинные экраны = паузa)
		instance.process_mode = Node.PROCESS_MODE_ALWAYS
		# Заполняем весь контейнер
		instance.anchors_preset = Control.PRESET_FULL_RECT
		instance.set_anchors_preset(Control.PRESET_FULL_RECT)
		screen_container.add_child(instance)
		_loaded_screens[index] = instance
		_wire_screen(index, instance)

	var screen: Control = _loaded_screens[index] as Control
	screen.visible = true
	# Обновляем металл на экране
	_refresh_screen_metal(index, screen)


func _hide_all_loaded_screens() -> void:
	for key: int in _loaded_screens.keys():
		var screen: Control = _loaded_screens[key] as Control
		if screen != null:
			screen.visible = false


func _wire_screen(index: int, screen: Control) -> void:
	# Подключаем кнопку настроек на каждом экране
	var settings_btn: Button = screen.get_node_or_null("%BtnSettings") as Button
	if settings_btn:
		settings_btn.pressed.connect(_on_btn_settings_pressed)

	# Для Screen 0 — подключаем CoreUpgrade
	if index == 0:
		_wire_screen_0(screen)


func _wire_screen_0(screen: Control) -> void:
	var core_plaque: PanelContainer = screen.get_node_or_null("%CorePlaque") as PanelContainer
	var core_cost: Label = screen.get_node_or_null("%CoreCost") as Label
	var core_level: Label = screen.get_node_or_null("%CoreLevelLabel") as Label
	var _core_btn: Button = screen.get_node_or_null("%CoreUpgradeBtn") as Button
	var level_bars: HBoxContainer = screen.get_node_or_null("%LevelBars") as HBoxContainer

	if core_plaque and core_cost and core_level and level_bars:
		_core_upgrade = CoreUpgradeControllerScript.new()
		_core_upgrade.setup(core_cost, core_level, level_bars, core_plaque)

		core_plaque.mouse_filter = Control.MOUSE_FILTER_STOP
		_make_children_mouse_passthrough(core_plaque)
		core_plaque.gui_input.connect(_on_core_plaque_input)

		_core_upgrade.refresh(ResourceManager.metal, _get_active_upgrade_id())


func _refresh_screen_metal(_index: int, screen: Control) -> void:
	var metal: int = ResourceManager.metal
	var max_metal: int = ResourceManager.max_metal

	var metal_counter_node: Label = screen.get_node_or_null("%MetalCounter") as Label
	if metal_counter_node:
		metal_counter_node.text = "%d / %d" % [metal, max_metal]

	var metal_bar_node: TextureProgressBar = screen.get_node_or_null("%MetalBar") as TextureProgressBar
	if metal_bar_node:
		metal_bar_node.max_value = max_metal
		metal_bar_node.value = metal


func _update_nav_highlights() -> void:
	for i in range(_nav_buttons.size()):
		var btn: Button = _nav_buttons[i]
		if i == 4:
			btn.add_theme_color_override("font_color", NAV_DISABLED_COLOR)
			btn.disabled = true
		elif i == _current_screen:
			btn.add_theme_color_override("font_color", NAV_ACTIVE_COLOR)
			btn.disabled = false
		else:
			btn.add_theme_color_override("font_color", NAV_INACTIVE_COLOR)
			btn.disabled = false


# ========== HUD верхняя панель ==========

func _refresh_hud() -> void:
	var metal: int = ResourceManager.metal
	var max_metal: int = ResourceManager.max_metal
	metal_label.text = "МЕТАЛЛ"
	metal_counter.text = "%d / %d" % [metal, max_metal]

	if metal_bar:
		metal_bar.max_value = max_metal
		metal_bar.value = metal

	if _core_upgrade != null:
		_core_upgrade.refresh(metal, _get_active_upgrade_id())

	# Обновляем металл на текущем загруженном экране
	if _loaded_screens.has(_current_screen):
		_refresh_screen_metal(_current_screen, _loaded_screens[_current_screen] as Control)


func _on_resource_changed(type: String, _new_total: int) -> void:
	if type == "metal":
		_refresh_hud()


func _on_resource_cap_reached(type: String, _current_total: int, _max_total: int) -> void:
	if type != "metal":
		return
	if metal_max_notice_stack != null:
		metal_max_notice_stack.show_notice()


func _on_upgrade_purchased(_id: String, _lvl: int) -> void:
	_refresh_hud()


# ========== Build Mode ==========

func _on_build_requested(module_type: String, _position: Vector2) -> void:
	_pending_build_type = module_type
	# BuildModeController уже обработал этот сигнал и вызвал build_mode_changed(true).
	# _is_in_build_mode = true, мы на screen 2 — устанавливаем контент верхней панели.
	if _is_in_build_mode:
		_build_mode_panel.enter_build_mode(module_type)


func _on_build_mode_changed(is_active: bool) -> void:
	_is_in_build_mode = is_active
	if is_active:
		_pre_build_screen = _current_screen
		_switch_to_screen(2, false)
		# Контент панели будет установлен в _on_build_requested (вызывается следующим)
	else:
		_build_mode_panel.exit_build_mode()


func _on_module_built(_type: String, _pos: Vector2) -> void:
	_is_in_build_mode = false
	_build_mode_panel.exit_build_mode()
	_refresh_hud()
	# Возвращаемся на предыдущий экран
	_switch_to_screen(_pre_build_screen)


func _on_build_mode_cancelled(_type: String) -> void:
	if _is_game_finished:
		return
	_is_in_build_mode = false
	_build_mode_panel.exit_build_mode()
	_refresh_hud()
	_switch_to_screen(_pre_build_screen)


# ========== Core Upgrade (Экран 0) ==========

func _on_core_plaque_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var upgrade_id: String = _get_active_upgrade_id()
		if upgrade_id.is_empty():
			return
		if _core_upgrade != null and _core_upgrade.try_purchase(upgrade_id):
			_refresh_hud()


func _get_active_upgrade_id() -> String:
	if UpgradeManager.get_upgrade_ids().has(Constants.UPGRADE_CORE_ID):
		return Constants.UPGRADE_CORE_ID
	var upgrade_ids: Array[String] = UpgradeManager.get_upgrade_ids()
	if upgrade_ids.is_empty():
		return ""
	return upgrade_ids[0]


# ========== Настройки ==========

func _on_btn_settings_pressed() -> void:
	if _is_game_finished:
		return
	AudioManager.play_ui_open()
	if settings_overlay and settings_overlay.has_method("open"):
		settings_overlay.open()


# ========== Оверлеи (Game Over / Confirm Exit) ==========

func _on_game_finished(outcome: String, _reason: String) -> void:
	_is_game_finished = true
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
	if ResourceManager.has_method("reset"):
		ResourceManager.reset()
	if UpgradeManager.has_method("reset"):
		UpgradeManager.reset()
	get_tree().reload_current_scene()


func _on_btn_confirm_exit_no_pressed() -> void:
	AudioManager.play_ui_open()
	_set_confirm_exit_visible(false)


func _on_btn_confirm_exit_yes_pressed() -> void:
	get_tree().paused = false
	AudioManager.play_ui_open()
	get_tree().change_scene_to_file("res://ui/start_menu.tscn")


func _set_confirm_exit_visible(value: bool) -> void:
	if confirm_exit_overlay == null:
		return
	confirm_exit_overlay.visible = value


# ========== Tutorial ==========

func _make_children_mouse_passthrough(parent: Control) -> void:
	for child in parent.get_children():
		if child is Control:
			var child_control := child as Control
			child_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_make_children_mouse_passthrough(child_control)


func _register_tutorial_targets() -> void:
	if _tutorial_focus == null:
		return
	_tutorial_focus.register_targets({
		"settings_button": btn_settings,
	})


func _on_raider_spawned(_position: Vector2) -> void:
	if _tutorial_focus == null:
		return
	if _first_raider_focus_target_registered:
		if _tutorial_focus.is_target_valid("first_raider"):
			return
		_tutorial_focus.unregister_target("first_raider")
		_first_raider_focus_target_registered = false
	call_deferred("_register_first_raider_focus_target")


func _on_raider_destroyed(_position: Vector2, _evolution_level: int, _source: String) -> void:
	if _tutorial_focus == null:
		return
	if not _first_raider_focus_target_registered:
		return
	if not _tutorial_focus.has_target("first_raider"):
		_first_raider_focus_target_registered = false
		return
	if not _tutorial_focus.is_target_valid("first_raider"):
		_tutorial_focus.unregister_target("first_raider")
		_first_raider_focus_target_registered = false


func _register_first_raider_focus_target() -> void:
	if _tutorial_focus == null:
		return
	if _first_raider_focus_target_registered:
		return

	var tree: SceneTree = get_tree()
	if tree == null:
		return

	var raiders: Array[Node] = tree.get_nodes_in_group("raiders")
	if raiders.is_empty():
		return

	for raider_any in raiders:
		if not (raider_any is Node2D):
			continue
		var raider: Node2D = raider_any as Node2D
		if not is_instance_valid(raider):
			continue
		var sprite: Sprite2D = raider.get_node_or_null("BodySprite") as Sprite2D
		if sprite != null and is_instance_valid(sprite):
			_tutorial_focus.register_target("first_raider", sprite)
			_first_raider_focus_target_registered = true
			return
		_tutorial_focus.register_target("first_raider", raider)
		_first_raider_focus_target_registered = true
		return


func _on_tutorial_focus_changed(target_id: String, accent_color: Color, _allow_interaction: bool) -> void:
	if _tutorial_focus != null:
		_tutorial_focus.focus_target(target_id, accent_color)


func _on_tutorial_focus_cleared() -> void:
	if _tutorial_focus != null:
		_tutorial_focus.clear_focus()


func _on_tutorial_action_requested(action_id: String) -> void:
	match action_id:
		"open_shop":
			_switch_to_screen(0)
		"buy_hull":
			_switch_to_screen(0)


func _get_focused_target_id() -> String:
	if _tutorial_focus == null:
		return ""
	return _tutorial_focus.get_focused_target_id()
