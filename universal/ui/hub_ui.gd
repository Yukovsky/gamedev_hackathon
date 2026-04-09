extends CanvasLayer
class_name HubUI

const PAGE_UPGRADES: int = 0
const PAGE_DEFENSE: int = 1
const PAGE_MAIN: int = 2
const PAGE_AUTOMATION: int = 3
const PAGE_TREE: int = 4
const PAGE_COUNT: int = 5
const PAGE_LAST_ACCESSIBLE: int = 3

const SWIPE_THRESHOLD_PX: float = 120.0
const SWIPE_MAX_VERTICAL_DRIFT_PX: float = 120.0

const START_MENU_SCENE: String = "res://ui/start_menu.tscn"
const TRAINING_SCENE: String = "res://ui/tutorial_first_call_mode.tscn"

const FONT_FILE: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const ICON_METAL: Texture2D = preload("res://assets/ui_icons/metal_coin_pixel.svg")
var ICON_SETTINGS: Texture2D = load("res://assets/ui_icons/settings_gear.svg")
const UpgradeCardScript: Script = preload("res://ui/upgrade_card.gd")
const ICON_PAGE_UPGRADES: Texture2D = preload("res://assets/sprites/core.png")
const ICON_PAGE_DEFENSE: Texture2D = preload("res://assets/sprites/turret.png")
const ICON_PAGE_MAIN: Texture2D = preload("res://assets/sprites/hull.png")
const ICON_PAGE_AUTOMATION: Texture2D = preload("res://assets/sprites/collector.png")
const ICON_PAGE_TREE: Texture2D = preload("res://assets/sprites/normal.png")
const ICON_HULL: Texture2D = preload("res://assets/sprites/hull.png")
const ICON_REACTOR: Texture2D = preload("res://assets/sprites/reactor.png")
const ICON_CORE: Texture2D = preload("res://assets/sprites/core.png")
const ICON_TURRET: Texture2D = preload("res://assets/sprites/turret.png")
const ICON_COLLECTOR: Texture2D = preload("res://assets/sprites/collector.png")
const ICON_PLACEHOLDER: Texture2D = preload("res://assets/sprites/normal.png")
const DEFAULT_COLLECTOR_CONFIG: CollectorConfig = preload("res://data/collector_config.tres")
const DEFAULT_TURRET_CONFIG: TurretConfig = preload("res://data/turret_config.tres")

const COLOR_PANEL_BG: Color = Color(0.027451, 0.0117647, 0.0901961, 0.92)
const COLOR_PANEL_BORDER: Color = Color(0.756863, 0.564706, 0.87451, 1.0)
const COLOR_PANEL_BORDER_SOFT: Color = Color(0.439216, 0.25098, 0.690196, 1.0)
const COLOR_PANEL_BORDER_ACTIVE: Color = Color(0.247, 0.808, 0.847, 1.0)
const COLOR_HEADER_BG: Color = Color(0.0117647, 0.0117647, 0.0313726, 0.93)
const COLOR_HEADER_BORDER: Color = Color(0.3137255, 0.2509804, 0.4705882, 1.0)
const COLOR_NAV_ACTIVE: Color = Color(0.247, 0.808, 0.847, 1.0)
const COLOR_NAV_INACTIVE: Color = Color(0.42, 0.34, 0.58, 1.0)
const COLOR_NAV_DISABLED: Color = Color(0.25, 0.22, 0.32, 0.6)
const COLOR_TEXT_PRIMARY: Color = Color(0.941176, 0.815686, 0.12549, 1.0)
const COLOR_TEXT_SECONDARY: Color = Color(0.815686, 0.627451, 0.941176, 1.0)
const COLOR_TEXT_GREEN: Color = Color(0.3, 0.85, 0.45, 1.0)
const COLOR_TEXT_RED: Color = Color(0.95, 0.32, 0.32, 1.0)

enum CardActionKind {
	MODULE_BUILD,
	UPGRADE_PURCHASE,
	PLACEHOLDER,
}

var _root_margin: MarginContainer
var _root_vbox: VBoxContainer
var _top_stack: VBoxContainer
var _header_panel: PanelContainer
var _header_margin: MarginContainer
var _normal_header: HBoxContainer
var _build_header: HBoxContainer
var _resource_group: HBoxContainer
var _resource_icon: TextureRect
var _resource_text_column: VBoxContainer
var _resource_title_label: Label
var _resource_counter_label: Label
var _resource_bar: TextureProgressBar
var _gear_button: Button
var _build_icon: TextureRect
var _build_text_column: VBoxContainer
var _build_title_label: Label
var _build_bonus_label: Label
var _notice_stack: MetalMaxNoticeStack
var _page_host: Control
var _pages_root: Control
var _pages: Array[Control] = []
var _nav_panel: PanelContainer
var _nav_buttons: Array[Button] = []
var _settings_overlay: ColorRect
var _settings_panel: PanelContainer
var _confirm_exit_overlay: ColorRect
var _confirm_exit_panel: PanelContainer
var _end_overlay: ColorRect
var _end_panel: PanelContainer
var _end_title_label: Label
var _end_reason_label: Label
var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_value_label: Label
var _sfx_value_label: Label
var _tutorial_focus: TutorialFocusController
var _first_raider_focus_target_registered: bool = false
var _is_game_finished: bool = false
var _is_build_mode_active: bool = false
var _active_page: int = PAGE_MAIN
var _previous_page_before_build: int = PAGE_MAIN
var _suppress_page_signal: bool = false
var _swipe_active: bool = false
var _swipe_start_pos: Vector2 = Vector2.ZERO
var _swipe_last_pos: Vector2 = Vector2.ZERO
var _ui_cards: Dictionary = {}
var _current_build_module_id: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tutorial_focus = TutorialFocusController.new()
	_build_ui()
	_apply_safe_area()
	_refresh_all()

	if not get_viewport().size_changed.is_connected(_apply_safe_area):
		get_viewport().size_changed.connect(_apply_safe_area)

	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.resource_cap_reached.connect(_on_resource_cap_reached)
	GameEvents.module_built.connect(_on_module_built)
	GameEvents.module_destroyed.connect(_on_module_destroyed)
	GameEvents.build_mode_changed.connect(_on_build_mode_changed)
	GameEvents.build_mode_cancelled.connect(_on_build_mode_cancelled)
	GameEvents.upgrade_purchased.connect(_on_upgrade_purchased)
	GameEvents.game_finished.connect(_on_game_finished)
	GameEvents.tutorial_focus_changed.connect(_on_tutorial_focus_changed)
	GameEvents.tutorial_focus_cleared.connect(_on_tutorial_focus_cleared)
	GameEvents.tutorial_action_requested.connect(_on_tutorial_action_requested)
	GameEvents.raider_spawned.connect(_on_raider_spawned)
	GameEvents.raider_destroyed.connect(_on_raider_destroyed)

	_register_tutorial_targets()
	call_deferred("_refresh_layout")


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_apply_safe_area):
		get_viewport().size_changed.disconnect(_apply_safe_area)


func _process(_delta: float) -> void:
	if _tutorial_focus != null:
		_tutorial_focus.process_focus_tracking()


func _unhandled_input(event: InputEvent) -> void:
	if _settings_overlay != null and _settings_overlay.visible:
		return

	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			_swipe_active = true
			_swipe_start_pos = touch_event.position
			_swipe_last_pos = touch_event.position
			return
		if _swipe_active:
			_swipe_last_pos = touch_event.position
			_finish_swipe(touch_event.position)
	elif event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
		if _swipe_active:
			_swipe_last_pos = drag_event.position
	elif event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			_swipe_active = true
			_swipe_start_pos = mouse_button.position
			_swipe_last_pos = mouse_button.position
		else:
			if _swipe_active:
				_swipe_last_pos = mouse_button.position
				_finish_swipe(mouse_button.position)
	elif event is InputEventMouseMotion and _swipe_active:
		var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
		_swipe_last_pos = mouse_motion.position


func _build_ui() -> void:
	_root_margin = MarginContainer.new()
	_root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_margin.add_theme_constant_override("margin_left", 24)
	_root_margin.add_theme_constant_override("margin_top", 24)
	_root_margin.add_theme_constant_override("margin_right", 24)
	_root_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(_root_margin)

	_root_vbox = VBoxContainer.new()
	_root_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_vbox.add_theme_constant_override("separation", 14)
	_root_margin.add_child(_root_vbox)

	_top_stack = VBoxContainer.new()
	_top_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_stack.add_theme_constant_override("separation", 8)
	_root_vbox.add_child(_top_stack)

	_header_panel = PanelContainer.new()
	_header_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_panel.custom_minimum_size = Vector2(0.0, 172.0)
	_header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_HEADER_BG, COLOR_HEADER_BORDER, 4))
	_top_stack.add_child(_header_panel)

	_header_margin = MarginContainer.new()
	_header_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_header_margin.add_theme_constant_override("margin_left", 16)
	_header_margin.add_theme_constant_override("margin_top", 12)
	_header_margin.add_theme_constant_override("margin_right", 16)
	_header_margin.add_theme_constant_override("margin_bottom", 12)
	_header_panel.add_child(_header_margin)

	_normal_header = _create_normal_header()
	_header_margin.add_child(_normal_header)

	_build_header = _create_build_header()
	_build_header.visible = false
	_header_margin.add_child(_build_header)

	_notice_stack = MetalMaxNoticeStack.new()
	_notice_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_stack.add_child(_notice_stack)
	_notice_stack.add_theme_constant_override("separation", 6)

	_page_host = Control.new()
	_page_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_host.clip_contents = true
	_root_vbox.add_child(_page_host)

	_pages_root = Control.new()
	_pages_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_host.add_child(_pages_root)

	_pages.clear()
	_pages.append(_create_main_page())
	_pages.append(_create_upgrade_page("УЛУЧШЕНИЯ КОРАБЛЯ", "Общие улучшения корпуса, реактора и ядра.", [
		_build_module_card("hull_card", CardActionKind.MODULE_BUILD, ICON_HULL, "КОРПУС", "Увеличивает запас металла и помогает расширять корабль.", Constants.MODULE_HULL, "", COLOR_TEXT_GREEN),
		_build_module_card("reactor_card", CardActionKind.MODULE_BUILD, ICON_REACTOR, "РЕАКТОР", "Расширяет питание корабля и открывает новые отсеки.", Constants.MODULE_REACTOR, "", COLOR_TEXT_PRIMARY),
		_build_module_card("core_card", CardActionKind.UPGRADE_PURCHASE, ICON_CORE, "ЯДРО", "Усиливает ядро и повышает награды за мусор.", "", Constants.UPGRADE_CORE_ID, COLOR_TEXT_PRIMARY),
	]))
	_pages.append(_create_upgrade_page("ОБОРОНА", "Турели и боевые модули для защиты корабля.", [
		_build_module_card("turret_card", CardActionKind.MODULE_BUILD, ICON_TURRET, "ТУРЕЛЬ", "Автоматически атакует налётчиков и удерживает линию обороны.", Constants.MODULE_TURRET, "", COLOR_TEXT_RED),
	]))
	_pages.append(_create_upgrade_page("АВТОМАТИЗАЦИЯ", "Автосбор и экономия кликов.", [
		_build_module_card("collector_card", CardActionKind.MODULE_BUILD, ICON_COLLECTOR, "СБОРЩИК", "Автоматически собирает мусор рядом с кораблём.", Constants.MODULE_COLLECTOR, "", COLOR_TEXT_PRIMARY),
	]))
	_pages.append(_create_tree_placeholder_page())

	for page_index: int in range(_pages.size()):
		var page: Control = _pages[page_index]
		page.position = Vector2.ZERO
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pages_root.add_child(page)

	_nav_panel = PanelContainer.new()
	_nav_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nav_panel.custom_minimum_size = Vector2(0.0, 128.0)
	_nav_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nav_panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_HEADER_BG, COLOR_HEADER_BORDER, 4))
	_root_vbox.add_child(_nav_panel)

	var nav_margin: MarginContainer = MarginContainer.new()
	nav_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nav_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	nav_margin.add_theme_constant_override("margin_left", 16)
	nav_margin.add_theme_constant_override("margin_top", 12)
	nav_margin.add_theme_constant_override("margin_right", 16)
	nav_margin.add_theme_constant_override("margin_bottom", 12)
	_nav_panel.add_child(nav_margin)

	var nav_row: HBoxContainer = HBoxContainer.new()
	nav_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nav_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_row.add_theme_constant_override("separation", 16)
	nav_margin.add_child(nav_row)

	_nav_buttons.clear()
	_nav_buttons.append(_create_nav_button(0, ICON_PAGE_UPGRADES, "УЛУЧШЕНИЯ", true))
	_nav_buttons.append(_create_nav_button(1, ICON_PAGE_DEFENSE, "ОБОРОНА", true))
	_nav_buttons.append(_create_nav_button(2, ICON_PAGE_MAIN, "КОРАБЛЬ", true))
	_nav_buttons.append(_create_nav_button(3, ICON_PAGE_AUTOMATION, "АВТО", true))
	_nav_buttons.append(_create_nav_button(4, ICON_PAGE_TREE, "ДЕРЕВО", false))
	for nav_button: Button in _nav_buttons:
		nav_row.add_child(nav_button)

	_build_settings_overlay()
	_build_confirm_exit_overlay()
	_build_end_overlay()
	_build_screen_borders()


func _create_normal_header() -> HBoxContainer:
	var header: HBoxContainer = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.size_flags_vertical = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 16)

	_resource_group = HBoxContainer.new()
	_resource_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resource_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resource_group.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_resource_group.add_theme_constant_override("separation", 14)
	header.add_child(_resource_group)

	_resource_icon = TextureRect.new()
	_resource_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resource_icon.custom_minimum_size = Vector2(44.0, 44.0)
	_resource_icon.texture = ICON_METAL
	_resource_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_resource_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_resource_group.add_child(_resource_icon)

	_resource_text_column = VBoxContainer.new()
	_resource_text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resource_text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resource_text_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_resource_text_column.add_theme_constant_override("separation", 4)
	_resource_group.add_child(_resource_text_column)

	_resource_title_label = Label.new()
	_resource_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resource_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resource_title_label.label_settings = _make_label_settings(24, COLOR_TEXT_PRIMARY)
	_resource_title_label.text = "МЕТАЛЛ"
	_resource_text_column.add_child(_resource_title_label)

	_resource_counter_label = Label.new()
	_resource_counter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resource_counter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resource_counter_label.label_settings = _make_label_settings(20, COLOR_TEXT_PRIMARY)
	_resource_counter_label.text = "0 / 0"
	_resource_text_column.add_child(_resource_counter_label)

	_resource_bar = TextureProgressBar.new()
	_resource_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resource_bar.custom_minimum_size = Vector2(0.0, 34.0)
	_resource_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resource_bar.nine_patch_stretch = true
	_resource_bar.texture_under = preload("res://assets/ui_icons/metal_bar_under_pixel.svg")
	_resource_bar.texture_progress = preload("res://assets/ui_icons/metal_bar_fill_pixel.svg")
	_resource_text_column.add_child(_resource_bar)

	_gear_button = _create_icon_button(ICON_SETTINGS, "", 82.0, 82.0)
	_gear_button.pressed.connect(_on_gear_button_pressed)
	header.add_child(_gear_button)
	return header


func _create_build_header() -> HBoxContainer:
	var header: HBoxContainer = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.size_flags_vertical = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 16)

	var build_group: HBoxContainer = HBoxContainer.new()
	build_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_group.size_flags_vertical = Control.SIZE_EXPAND_FILL
	build_group.add_theme_constant_override("separation", 14)
	header.add_child(build_group)

	_build_icon = TextureRect.new()
	_build_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_icon.custom_minimum_size = Vector2(52.0, 52.0)
	_build_icon.texture = ICON_PAGE_MAIN
	_build_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_build_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	build_group.add_child(_build_icon)

	_build_text_column = VBoxContainer.new()
	_build_text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_text_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_text_column.add_theme_constant_override("separation", 4)
	build_group.add_child(_build_text_column)

	_build_title_label = Label.new()
	_build_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_title_label.label_settings = _make_label_settings(24, COLOR_TEXT_PRIMARY)
	_build_title_label.text = "РЕЖИМ СТРОИТЕЛЬСТВА"
	_build_text_column.add_child(_build_title_label)

	_build_bonus_label = Label.new()
	_build_bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_bonus_label.label_settings = _make_label_settings(22, COLOR_TEXT_GREEN)
	_build_bonus_label.text = ""
	_build_text_column.add_child(_build_bonus_label)

	_gear_button = _create_icon_button(ICON_SETTINGS, "", 82.0, 82.0)
	_gear_button.pressed.connect(_on_gear_button_pressed)
	header.add_child(_gear_button)
	return header


func _create_main_page() -> Control:
	var page: Control = Control.new()
	page.name = "MainPage"
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return page


func _create_upgrade_page(title: String, subtitle: String, cards: Array) -> Control:
	var page_root: Control = Control.new()
	page_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var page_margin: MarginContainer = MarginContainer.new()
	page_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_margin.add_theme_constant_override("margin_left", 14)
	page_margin.add_theme_constant_override("margin_top", 14)
	page_margin.add_theme_constant_override("margin_right", 14)
	page_margin.add_theme_constant_override("margin_bottom", 14)
	page_root.add_child(page_margin)

	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL_BG, COLOR_PANEL_BORDER, 4))
	page_margin.add_child(panel)

	var panel_margin: MarginContainer = MarginContainer.new()
	panel_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_margin.add_theme_constant_override("margin_left", 20)
	panel_margin.add_theme_constant_override("margin_top", 20)
	panel_margin.add_theme_constant_override("margin_right", 20)
	panel_margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(panel_margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	panel_margin.add_child(column)

	var title_label: Label = Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.label_settings = _make_label_settings(30, COLOR_TEXT_PRIMARY)
	title_label.text = title
	column.add_child(title_label)

	var subtitle_label: Label = Label.new()
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.label_settings = _make_label_settings(16, COLOR_TEXT_SECONDARY)
	subtitle_label.text = subtitle
	column.add_child(subtitle_label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_theme_constant_override("scroll_deadzone", 12)
	column.add_child(scroll)

	var list_column: VBoxContainer = VBoxContainer.new()
	list_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_column.add_theme_constant_override("separation", 14)
	scroll.add_child(list_column)

	for card_any in cards:
		if card_any != null:
			list_column.add_child(card_any)

	var bottom_spacer: Control = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0.0, 12.0)
	list_column.add_child(bottom_spacer)

	return page_root


func _create_tree_placeholder_page() -> Control:
	var page_root: Control = Control.new()
	page_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var page_margin: MarginContainer = MarginContainer.new()
	page_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_margin.add_theme_constant_override("margin_left", 14)
	page_margin.add_theme_constant_override("margin_top", 14)
	page_margin.add_theme_constant_override("margin_right", 14)
	page_margin.add_theme_constant_override("margin_bottom", 14)
	page_root.add_child(page_margin)

	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL_BG, COLOR_PANEL_BORDER, 4))
	page_margin.add_child(panel)

	var panel_margin: MarginContainer = MarginContainer.new()
	panel_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_margin.add_theme_constant_override("margin_left", 24)
	panel_margin.add_theme_constant_override("margin_top", 24)
	panel_margin.add_theme_constant_override("margin_right", 24)
	panel_margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(panel_margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	panel_margin.add_child(column)

	var title_label: Label = Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.label_settings = _make_label_settings(32, COLOR_TEXT_PRIMARY)
	title_label.text = "ДЕРЕВО УЛУЧШЕНИЙ"
	column.add_child(title_label)

	var placeholder_card = _build_module_card(
		"tree_placeholder",
		CardActionKind.PLACEHOLDER,
		ICON_PLACEHOLDER,
		"СКОРО",
		"Этот экран ещё не реализован и пока недоступен.",
		"",
		"",
		Color(0.68, 0.6, 0.8, 1.0),
		false,
		true
	)
	column.add_child(placeholder_card)
	return page_root


func _build_module_card(
	card_name: String,
	kind: int,
	icon: Texture2D,
	title: String,
	description: String,
	module: String,
	upgrade: String,
	accent_color: Color,
	available: bool = true,
	is_maxed: bool = false
) -> Node:
	var card = UpgradeCardScript.new()
	card.name = card_name
	card.action_kind = kind
	card.module_id = module
	card.upgrade_id = upgrade
	card.card_pressed.connect(_on_card_pressed)
	card.configure(kind, icon, title, description, "", accent_color, available, is_maxed, module, upgrade)
	_ui_cards[card_name] = card
	return card


func _create_nav_button(page_index: int, icon: Texture2D, tooltip: String, enabled: bool) -> Button:
	var nav_button: Button = _create_icon_button(icon, tooltip, 92.0, 92.0)
	nav_button.disabled = not enabled
	if not enabled:
		nav_button.modulate = COLOR_NAV_DISABLED
	else:
		nav_button.pressed.connect(_on_nav_button_pressed.bind(page_index))
	return nav_button


func _create_icon_button(icon: Texture2D, tooltip: String, size_px: float, icon_size_px: float) -> Button:
	var button: Button = Button.new()
	button.text = " "
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(size_px, size_px)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _make_round_button_style(COLOR_NAV_INACTIVE, COLOR_PANEL_BORDER_SOFT))
	button.add_theme_stylebox_override("hover", _make_round_button_style(COLOR_NAV_ACTIVE, COLOR_PANEL_BORDER_ACTIVE))
	button.add_theme_stylebox_override("pressed", _make_round_button_style(COLOR_NAV_ACTIVE.lightened(0.1), COLOR_PANEL_BORDER_ACTIVE))
	button.add_theme_stylebox_override("disabled", _make_round_button_style(COLOR_NAV_INACTIVE.darkened(0.3), COLOR_PANEL_BORDER_SOFT))

	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(icon_size_px, icon_size_px)
	icon_rect.texture = icon
	button.add_child(icon_rect)
	return button


func _build_settings_overlay() -> void:
	_settings_overlay = ColorRect.new()
	_settings_overlay.visible = false
	_settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.color = Color(0.039, 0.02, 0.125, 0.72)
	_settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_settings_overlay)

	var root: CenterContainer = CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.add_child(root)

	_settings_panel = PanelContainer.new()
	_settings_panel.custom_minimum_size = Vector2(880.0, 1020.0)
	_settings_panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL_BG, COLOR_PANEL_BORDER, 4))
	root.add_child(_settings_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	_settings_panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 22)
	margin.add_child(column)

	var title_label: Label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.label_settings = _make_label_settings(44, COLOR_TEXT_PRIMARY)
	title_label.text = "НАСТРОЙКИ"
	column.add_child(title_label)

	column.add_child(_create_slider_row("МУЗЫКА", true))
	column.add_child(_create_slider_row("ЗВУКИ", false))

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 8.0)
	column.add_child(spacer)

	var training_button: Button = _create_text_button("ПРОЙТИ ОБУЧЕНИЕ", COLOR_TEXT_PRIMARY)
	training_button.custom_minimum_size = Vector2(0.0, 120.0)
	training_button.pressed.connect(_on_btn_training_pressed)
	column.add_child(training_button)

	var menu_button: Button = _create_text_button("В ГЛАВНОЕ МЕНЮ", COLOR_TEXT_RED)
	menu_button.custom_minimum_size = Vector2(0.0, 120.0)
	menu_button.pressed.connect(_on_btn_main_menu_pressed)
	column.add_child(menu_button)

	var close_button: Button = _create_text_button("НАЗАД", COLOR_TEXT_PRIMARY)
	close_button.custom_minimum_size = Vector2(0.0, 100.0)
	close_button.pressed.connect(_on_btn_settings_close_pressed)
	column.add_child(close_button)


func _build_confirm_exit_overlay() -> void:
	_confirm_exit_overlay = ColorRect.new()
	_confirm_exit_overlay.visible = false
	_confirm_exit_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_exit_overlay.color = Color(0.0, 0.0, 0.0, 0.82)
	_confirm_exit_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_confirm_exit_overlay)

	var root: CenterContainer = CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_exit_overlay.add_child(root)

	_confirm_exit_panel = PanelContainer.new()
	_confirm_exit_panel.custom_minimum_size = Vector2(860.0, 520.0)
	_confirm_exit_panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL_BG, COLOR_PANEL_BORDER, 4))
	root.add_child(_confirm_exit_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 30)
	_confirm_exit_panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 22)
	margin.add_child(column)

	var title_label: Label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.label_settings = _make_label_settings(42, Color(1.0, 0.58, 0.58, 1.0))
	title_label.text = "В ГЛАВНОЕ МЕНЮ"
	column.add_child(title_label)

	var description: Label = Label.new()
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.label_settings = _make_label_settings(24, COLOR_TEXT_SECONDARY)
	description.text = "Прогресс текущего захода не сохранится.\nПерейти в главное меню?"
	column.add_child(description)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 16)
	column.add_child(button_row)

	var cancel_button: Button = _create_text_button("ОТМЕНА", COLOR_TEXT_PRIMARY)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.custom_minimum_size = Vector2(0.0, 96.0)
	cancel_button.pressed.connect(_on_btn_confirm_exit_no_pressed)
	button_row.add_child(cancel_button)

	var confirm_button: Button = _create_text_button("ПЕРЕЙТИ", Color(1.0, 0.58, 0.58, 1.0))
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_button.custom_minimum_size = Vector2(0.0, 96.0)
	confirm_button.pressed.connect(_on_btn_confirm_exit_yes_pressed)
	button_row.add_child(confirm_button)


func _build_end_overlay() -> void:
	_end_overlay = ColorRect.new()
	_end_overlay.visible = false
	_end_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_overlay.color = Color(0.0, 0.0, 0.0, 0.82)
	_end_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_end_overlay)

	var root: CenterContainer = CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_overlay.add_child(root)

	_end_panel = PanelContainer.new()
	_end_panel.custom_minimum_size = Vector2(900.0, 520.0)
	_end_panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL_BG, COLOR_PANEL_BORDER, 4))
	root.add_child(_end_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 30)
	_end_panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 22)
	margin.add_child(column)

	_end_title_label = Label.new()
	_end_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_title_label.label_settings = _make_label_settings(72, COLOR_TEXT_PRIMARY)
	_end_title_label.text = "GAME OVER"
	column.add_child(_end_title_label)

	_end_reason_label = Label.new()
	_end_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_reason_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_reason_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_end_reason_label.label_settings = _make_label_settings(28, COLOR_TEXT_SECONDARY)
	_end_reason_label.text = "Причина завершения"
	column.add_child(_end_reason_label)

	var restart_button: Button = _create_text_button("ПЕРЕЗАПУСК", Color.WHITE)
	restart_button.custom_minimum_size = Vector2(0.0, 96.0)
	restart_button.pressed.connect(_on_btn_restart_pressed)
	column.add_child(restart_button)


func _build_screen_borders() -> void:
	var outer: PanelContainer = PanelContainer.new()
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_stylebox_override("panel", _make_border_style(Color(0.815686, 0.627451, 0.941176, 0.24), 24))
	add_child(outer)

	var inner: PanelContainer = PanelContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_stylebox_override("panel", _make_border_style(Color(0.756863, 0.564706, 0.87451, 0.16), 12))
	add_child(inner)


func _create_slider_row(title: String, is_music: bool) -> VBoxContainer:
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var header: HBoxContainer = HBoxContainer.new()
	row.add_child(header)

	var title_label: Label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.label_settings = _make_label_settings(30, COLOR_TEXT_SECONDARY)
	title_label.text = title
	header.add_child(title_label)

	var value_label: Label = Label.new()
	value_label.label_settings = _make_label_settings(30, COLOR_TEXT_PRIMARY)
	value_label.text = "100%"
	header.add_child(value_label)

	var slider: HSlider = HSlider.new()
	slider.custom_minimum_size = Vector2(0.0, 42.0)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	if is_music:
		_music_slider = slider
		_music_value_label = value_label
		slider.value = AudioManager.get_music_volume()
		slider.value_changed.connect(_on_music_slider_changed)
	else:
		_sfx_slider = slider
		_sfx_value_label = value_label
		slider.value = AudioManager.get_sfx_volume()
		slider.value_changed.connect(_on_sfx_slider_changed)
		slider.drag_ended.connect(_on_sfx_slider_drag_ended)

	return row


func _create_text_button(text: String, text_color: Color) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", FONT_FILE)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.227451, 0.117647, 0.431373, 1.0), COLOR_PANEL_BORDER, 3))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.305882, 0.168627, 0.564706, 1.0), Color(0.815686, 0.627451, 0.941176, 1.0), 3))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.305882, 0.168627, 0.564706, 1.0), Color(0.815686, 0.627451, 0.941176, 1.0), 3))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.101961, 0.0509804, 0.207843, 0.5), Color(0.439216, 0.25098, 0.690196, 0.5), 3))
	return button


func _make_panel_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	return style


func _make_border_style(border: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	return style


func _make_button_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style


func _make_round_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	return style


func _make_label_settings(font_size: int, font_color: Color) -> LabelSettings:
	var settings: LabelSettings = LabelSettings.new()
	settings.font = FONT_FILE
	settings.font_size = font_size
	settings.font_color = font_color
	return settings


func _apply_safe_area() -> void:
	if _root_margin == null:
		return

	var window_size: Vector2i = DisplayServer.window_get_size()
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	if safe_area.size.x <= 0 or safe_area.size.y <= 0:
		safe_area = Rect2i(Vector2i.ZERO, window_size)

	var safe_left: int = max(0, int(safe_area.position.x))
	var safe_top: int = max(0, int(safe_area.position.y))
	var safe_right: int = max(0, int(window_size.x - safe_area.end.x))
	var safe_bottom: int = max(0, int(window_size.y - safe_area.end.y))

	_root_margin.add_theme_constant_override("margin_left", 24 + safe_left)
	_root_margin.add_theme_constant_override("margin_top", 24 + safe_top)
	_root_margin.add_theme_constant_override("margin_right", 24 + safe_right)
	_root_margin.add_theme_constant_override("margin_bottom", 24 + safe_bottom)
	_refresh_layout()


func _refresh_layout() -> void:
	if _page_host == null or _pages_root == null:
		return

	var host_size: Vector2 = _page_host.size
	if host_size == Vector2.ZERO:
		host_size = _page_host.get_rect().size
	if host_size == Vector2.ZERO:
		return

	for index: int in range(_pages.size()):
		var page: Control = _pages[index]
		page.size = host_size
		page.position = Vector2(host_size.x * float(index), 0.0)
		page.custom_minimum_size = host_size

	_pages_root.size = Vector2(host_size.x * float(_pages.size()), host_size.y)
	_pages_root.position.x = -host_size.x * float(_active_page)
	_update_nav_state()
	_update_header_state()


func _refresh_all() -> void:
	_refresh_resource_header()
	_refresh_cards()
	_update_nav_state()
	_update_header_state()


func _refresh_resource_header() -> void:
	if _resource_counter_label == null:
		return
	var metal: int = ResourceManager.metal
	var max_metal: int = ResourceManager.max_metal
	_resource_counter_label.text = "%d / %d" % [metal, max_metal]
	_resource_bar.max_value = max(1, max_metal)
	_resource_bar.value = metal
	if _notice_stack != null and _resource_title_label != null:
		_notice_stack.set_notice_font(_resource_title_label.get_theme_font("font"))


func _refresh_cards() -> void:
	for card_variant in _ui_cards.values():
		if card_variant == null or not is_instance_valid(card_variant):
			continue
		var card = card_variant
		_refresh_card_state(card)


func _refresh_card_state(card: Node) -> void:
	if card == null or not is_instance_valid(card):
		return

	var metal: int = ResourceManager.metal
	match card.action_kind:
		CardActionKind.MODULE_BUILD:
			if card.module_id.is_empty():
				return
			var cost: int = ResourceManager.get_current_module_cost(card.module_id)
			card.set_price_text(_format_cost(cost))
			card.set_available(metal >= cost)
			card.set_maxed(false)
			if card.module_id == Constants.MODULE_HULL:
				card.configure(card.action_kind, ICON_HULL, "КОРПУС", "Увеличивает запас металла и помогает расширять корабль.", _format_cost(cost), COLOR_TEXT_GREEN, metal >= cost, false, card.module_id, card.upgrade_id)
			elif card.module_id == Constants.MODULE_REACTOR:
				card.configure(card.action_kind, ICON_REACTOR, "РЕАКТОР", "Расширяет питание корабля и открывает новые отсеки.", _format_cost(cost), COLOR_TEXT_PRIMARY, metal >= cost, false, card.module_id, card.upgrade_id)
			elif card.module_id == Constants.MODULE_TURRET:
				card.configure(card.action_kind, ICON_TURRET, "ТУРЕЛЬ", "Автоматически атакует налётчиков и удерживает линию обороны.", _format_cost(cost), COLOR_TEXT_RED, metal >= cost, false, card.module_id, card.upgrade_id)
			elif card.module_id == Constants.MODULE_COLLECTOR:
				card.configure(card.action_kind, ICON_COLLECTOR, "СБОРЩИК", "Автоматически собирает мусор рядом с кораблём.", _format_cost(cost), COLOR_TEXT_PRIMARY, metal >= cost, false, card.module_id, card.upgrade_id)
			else:
				card.configure(card.action_kind, ICON_PLACEHOLDER, card.name, "", _format_cost(cost), COLOR_TEXT_PRIMARY, metal >= cost, false, card.module_id, card.upgrade_id)
		CardActionKind.UPGRADE_PURCHASE:
			if card.upgrade_id.is_empty():
				return
			var upgrade_level: int = UpgradeManager.get_upgrade_level(card.upgrade_id)
			var max_level: int = UpgradeManager.get_upgrade_max_level(card.upgrade_id)
			if upgrade_level >= max_level:
				card.configure(card.action_kind, ICON_CORE, "ЯДРО", "Усиление ядра повышает награды за мусор и общую эффективность.", "MAX", COLOR_TEXT_PRIMARY, false, true, card.module_id, card.upgrade_id)
				return
			var upgrade_cost: int = UpgradeManager.get_upgrade_next_cost(card.upgrade_id)
			card.configure(card.action_kind, ICON_CORE, "ЯДРО", "Усиление ядра повышает награды за мусор и общую эффективность.", _format_cost(upgrade_cost), COLOR_TEXT_PRIMARY, metal >= upgrade_cost, false, card.module_id, card.upgrade_id)
		CardActionKind.PLACEHOLDER:
			card.configure(card.action_kind, ICON_PLACEHOLDER, "СКОРО", "Этот экран пока не реализован.", "--", Color(0.68, 0.6, 0.8, 1.0), false, true, card.module_id, card.upgrade_id)


func _format_cost(cost: int) -> String:
	if cost < 0:
		return "MAX"
	return "%d +" % cost


func _update_nav_state() -> void:
	for index: int in range(_nav_buttons.size()):
		var button: Button = _nav_buttons[index]
		if button == null or not is_instance_valid(button):
			continue
		if button.disabled:
			button.modulate = COLOR_NAV_DISABLED
			continue
		if index == _active_page:
			button.modulate = COLOR_NAV_ACTIVE
		else:
			button.modulate = COLOR_NAV_INACTIVE


func _update_header_state() -> void:
	if _normal_header == null or _build_header == null:
		return
	_normal_header.visible = not _is_build_mode_active
	_build_header.visible = _is_build_mode_active
	if _build_icon != null:
		_build_icon.texture = _get_build_icon_for_module(_current_build_module_id)
	if _build_title_label != null:
		_build_title_label.text = _get_build_title(_current_build_module_id)
	if _build_bonus_label != null:
		_build_bonus_label.text = _get_build_bonus_text(_current_build_module_id)


func _get_build_icon_for_module(module_id: String) -> Texture2D:
	match module_id:
		Constants.MODULE_HULL:
			return ICON_HULL
		Constants.MODULE_REACTOR:
			return ICON_REACTOR
		Constants.MODULE_TURRET:
			return ICON_TURRET
		Constants.MODULE_COLLECTOR:
			return ICON_COLLECTOR
		_:
			return ICON_PAGE_MAIN


func _get_build_title(module_id: String) -> String:
	match module_id:
		Constants.MODULE_HULL:
			return "КОРПУС"
		Constants.MODULE_REACTOR:
			return "РЕАКТОР"
		Constants.MODULE_TURRET:
			return "ТУРЕЛЬ"
		Constants.MODULE_COLLECTOR:
			return "СБОРЩИК"
		_:
			return "СТРОИТЕЛЬСТВО"


func _get_build_bonus_text(module_id: String) -> String:
	match module_id:
		Constants.MODULE_HULL:
			return "МЕТАЛЛ МАКС +%d" % Constants.get_hull_metal_bonus()
		Constants.MODULE_REACTOR:
			return "РАДИУС ПИТАНИЯ +1"
		Constants.MODULE_TURRET:
			return "УРОНА В СЕК +%d" % int(roundf(TURRET_DAMAGE_PER_SEC()))
		Constants.MODULE_COLLECTOR:
			return "МЕТАЛЛ/СЕК +%.1f" % COLLECTOR_METAL_PER_SEC()
		_:
			return ""


func TURRET_DAMAGE_PER_SEC() -> float:
	if DEFAULT_TURRET_CONFIG == null:
		return 0.0
	return float(DEFAULT_TURRET_CONFIG.turret_damage) / max(0.1, DEFAULT_TURRET_CONFIG.fire_cooldown_sec)


func COLLECTOR_METAL_PER_SEC() -> float:
	if DEFAULT_COLLECTOR_CONFIG == null:
		return 0.0
	return 1.0 / max(0.1, DEFAULT_COLLECTOR_CONFIG.collect_cooldown_sec)


func _finish_swipe(end_pos: Vector2) -> void:
	if not _swipe_active:
		return
	_swipe_active = false
	var delta: Vector2 = end_pos - _swipe_start_pos
	if abs(delta.x) < SWIPE_THRESHOLD_PX:
		return
	if abs(delta.y) > SWIPE_MAX_VERTICAL_DRIFT_PX:
		return
	if delta.x < 0.0:
		_go_to_page(_active_page + 1)
	else:
		_go_to_page(_active_page - 1)


func _go_to_page(page_index: int, force: bool = false) -> void:
	if page_index < 0 or page_index >= PAGE_COUNT:
		return
	if page_index == PAGE_TREE and not force:
		return
	if _settings_overlay != null and _settings_overlay.visible:
		return
	if _is_build_mode_active and not force:
		return
	if page_index == _active_page:
		_update_nav_state()
		_update_header_state()
		return

	_previous_page_before_build = _active_page if _is_build_mode_active else _previous_page_before_build
	_active_page = page_index
	_update_pages_position()
	_update_nav_state()
	_update_header_state()
	_emit_page_state_signals()


func _update_pages_position() -> void:
	if _page_host == null or _pages_root == null:
		return
	var host_size: Vector2 = _page_host.size
	if host_size == Vector2.ZERO:
		host_size = _page_host.get_rect().size
	if host_size == Vector2.ZERO:
		return
	_pages_root.position.x = -host_size.x * float(_active_page)


func _emit_page_state_signals() -> void:
	if _suppress_page_signal:
		return
	if _active_page == PAGE_MAIN:
		GameEvents.shop_closed.emit()
	else:
		GameEvents.shop_opened.emit()


func _on_nav_button_pressed(page_index: int) -> void:
	AudioManager.play_ui_open()
	_go_to_page(page_index)


func _on_card_pressed(card: Node) -> void:
	if card == null or not is_instance_valid(card) or card.disabled:
		return
	AudioManager.play_ui_open()
	match card.action_kind:
		CardActionKind.MODULE_BUILD:
			_begin_module_build(card.module_id)
		CardActionKind.UPGRADE_PURCHASE:
			_buy_upgrade(card.upgrade_id)
		CardActionKind.PLACEHOLDER:
			return


func _begin_module_build(module_id: String) -> void:
	if module_id.is_empty():
		return
	_previous_page_before_build = _active_page
	_current_build_module_id = module_id
	_go_to_page(PAGE_MAIN, true)
	GameEvents.build_requested.emit(module_id, Vector2.ZERO)
	_update_header_state()


func _buy_upgrade(upgrade_id: String) -> void:
	if upgrade_id.is_empty():
		return
	if UpgradeManager.purchase(upgrade_id):
		_refresh_all()


func _on_resource_changed(type: String, _new_total: int) -> void:
	if type != "metal":
		return
	_refresh_all()


func _on_resource_cap_reached(type: String, _current_total: int, _max_total: int) -> void:
	if type == "metal" and _notice_stack != null:
		_notice_stack.show_notice()


func _on_module_built(_type: String, _pos: Vector2) -> void:
	_current_build_module_id = ""
	if _is_build_mode_active:
		return
	if _previous_page_before_build != PAGE_MAIN:
		_go_to_page(_previous_page_before_build, true)
		_previous_page_before_build = PAGE_MAIN
	_refresh_all()


func _on_module_destroyed(_type: String, _pos: Vector2) -> void:
	_refresh_all()


func _on_build_mode_changed(is_active: bool) -> void:
	_is_build_mode_active = is_active
	if is_active:
		return
	_update_header_state()
	if _previous_page_before_build != PAGE_MAIN:
		_go_to_page(_previous_page_before_build, true)
		_previous_page_before_build = PAGE_MAIN
	_refresh_all()


func _on_build_mode_cancelled(_module_type: String) -> void:
	_current_build_module_id = ""
	_refresh_all()


func _on_upgrade_purchased(_id: String, _lvl: int) -> void:
	_refresh_all()


func _on_game_finished(outcome: String, reason: String) -> void:
	_is_game_finished = true
	_end_overlay.visible = true
	set_process_unhandled_input(false)
	if outcome == "win":
		_end_title_label.text = "ПОБЕДА"
		_end_reason_label.text = "Миссия выполнена!"
	else:
		_end_title_label.text = "GAME OVER"
		_end_reason_label.text = reason
	get_tree().paused = true


func _on_gear_button_pressed() -> void:
	if _settings_overlay == null:
		return
	AudioManager.play_ui_open()
	_settings_overlay.visible = not _settings_overlay.visible
	if _settings_overlay.visible:
		_refresh_settings_values()


func _on_btn_settings_close_pressed() -> void:
	if _settings_overlay != null:
		AudioManager.play_ui_open()
		_settings_overlay.visible = false


func _on_btn_training_pressed() -> void:
	if not ResourceLoader.exists(TRAINING_SCENE):
		push_warning("Training scene not found: %s" % TRAINING_SCENE)
		return
	AudioManager.play_ui_open()
	get_tree().change_scene_to_file(TRAINING_SCENE)


func _on_btn_main_menu_pressed() -> void:
	if _confirm_exit_overlay != null:
		AudioManager.play_ui_open()
		_confirm_exit_overlay.visible = true


func _on_btn_confirm_exit_no_pressed() -> void:
	if _confirm_exit_overlay != null:
		AudioManager.play_ui_open()
		_confirm_exit_overlay.visible = false


func _on_btn_confirm_exit_yes_pressed() -> void:
	AudioManager.play_ui_open()
	get_tree().paused = false
	get_tree().change_scene_to_file(START_MENU_SCENE)


func _on_btn_restart_pressed() -> void:
	get_tree().paused = false
	if ResourceManager.has_method("reset"):
		ResourceManager.reset()
	if UpgradeManager.has_method("reset"):
		UpgradeManager.reset()
	get_tree().reload_current_scene()


func _on_music_slider_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
	_refresh_settings_values()


func _on_sfx_slider_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	_refresh_settings_values()


func _on_sfx_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		AudioManager.play_ui_open()


func _refresh_settings_values() -> void:
	if _music_slider != null:
		_music_value_label.text = "%d%%" % int(roundf(_music_slider.value * 100.0))
	if _sfx_slider != null:
		_sfx_value_label.text = "%d%%" % int(roundf(_sfx_slider.value * 100.0))


func _register_tutorial_targets() -> void:
	if _tutorial_focus == null:
		return
	_tutorial_focus.register_targets({
		"shop_button": _nav_buttons[0] if _nav_buttons.size() > 0 else null,
		"hull": _ui_cards.get("hull_card", null),
		"reactor": _ui_cards.get("reactor_card", null),
		"collector": _ui_cards.get("collector_card", null),
		"turret": _ui_cards.get("turret_card", null),
		"core": _ui_cards.get("core_card", null),
	})


func _on_tutorial_focus_changed(target_id: String, accent_color: Color, _allow_interaction: bool) -> void:
	if _tutorial_focus != null:
		_tutorial_focus.focus_target(target_id, accent_color)


func _on_tutorial_focus_cleared() -> void:
	if _tutorial_focus != null:
		_tutorial_focus.clear_focus()


func _on_tutorial_action_requested(action_id: String) -> void:
	match action_id:
		"open_shop":
			_go_to_page(PAGE_UPGRADES)
		"buy_hull":
			var hull_card: Variant = _ui_cards.get("hull_card", null)
			if hull_card != null and is_instance_valid(hull_card):
				_on_card_pressed(hull_card)


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

	for raider_any: Node in raiders:
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
