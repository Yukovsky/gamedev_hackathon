extends CanvasLayer
## Главный UI-контроллер игры.
## Управляет HUD, магазином, экраном завершения и туториалом.
## Взаимодействует с игрой через Event Bus (GameEvents).

const ShopStateControllerScript: Script = preload("res://ui/shop_state_controller.gd")
const TutorialFocusControllerScript: Script = preload("res://ui/tutorial_focus_controller.gd")
const CoreUpgradeControllerScript: Script = preload("res://ui/core_upgrade_controller.gd")

@export var ui_base_margin_left: int = 24
@export var ui_base_margin_top: int = 24
@export var ui_base_margin_right: int = 24
@export var ui_base_margin_bottom: int = 60

@export var shop_base_margin_left: int = 30
@export var shop_base_margin_top: int = 64
@export var shop_base_margin_right: int = 30
@export var shop_base_margin_bottom: int = 80

@onready var root_margin_container: MarginContainer = $MarginContainer
@onready var shop_center_container: MarginContainer = $ShopOverlay/Center
@onready var end_center_container: Control = $EndOverlay/Center

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
var _shop_state: ShopStateController
var _tutorial_focus: TutorialFocusController
var _core_upgrade: CoreUpgradeController
var _first_raider_focus_target_registered: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shop_state = ShopStateControllerScript.new() as ShopStateController
	_tutorial_focus = TutorialFocusControllerScript.new() as TutorialFocusController
	_core_upgrade = CoreUpgradeControllerScript.new() as CoreUpgradeController
	_core_upgrade.setup(core_cost_label, core_level_label, level_bars_container, core_plaque)
	_apply_safe_area()
	if not get_viewport().size_changed.is_connected(_apply_safe_area):
		get_viewport().size_changed.connect(_apply_safe_area)

	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.module_built.connect(_on_module_built)
	GameEvents.build_mode_cancelled.connect(_on_build_mode_cancelled)
	if GameEvents.has_signal("game_finished"):
		GameEvents.game_finished.connect(_on_game_finished)
	GameEvents.upgrade_purchased.connect(_on_upgrade_purchased)
	GameEvents.tutorial_focus_changed.connect(_on_tutorial_focus_changed)
	GameEvents.tutorial_focus_cleared.connect(_on_tutorial_focus_cleared)
	GameEvents.tutorial_action_requested.connect(_on_tutorial_action_requested)
	GameEvents.raider_spawned.connect(_on_raider_spawned)
	GameEvents.raider_destroyed.connect(_on_raider_destroyed)

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

	_register_tutorial_targets()

	_refresh_ui()
	_set_shop_open(false, false)
	end_overlay.visible = false

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

	# Фон остается full-screen, а интерактивный UI получает safe-area отступы.
	root_margin_container.add_theme_constant_override("margin_left", ui_base_margin_left + safe_left)
	root_margin_container.add_theme_constant_override("margin_top", ui_base_margin_top + safe_top)
	root_margin_container.add_theme_constant_override("margin_right", ui_base_margin_right + safe_right)
	root_margin_container.add_theme_constant_override("margin_bottom", ui_base_margin_bottom + safe_bottom)

	shop_center_container.add_theme_constant_override("margin_left", shop_base_margin_left + safe_left)
	shop_center_container.add_theme_constant_override("margin_top", shop_base_margin_top + safe_top)
	shop_center_container.add_theme_constant_override("margin_right", shop_base_margin_right + safe_right)
	shop_center_container.add_theme_constant_override("margin_bottom", shop_base_margin_bottom + safe_bottom)

	end_center_container.offset_left = float(safe_left)
	end_center_container.offset_top = float(safe_top)
	end_center_container.offset_right = -float(safe_right)
	end_center_container.offset_bottom = -float(safe_bottom)

func _process(_delta: float) -> void:
	if _tutorial_focus != null:
		_tutorial_focus.process_focus_tracking()

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

	# Обновление ядра через контроллер
	if _core_upgrade != null:
		_core_upgrade.refresh(metal, _get_active_upgrade_id())


func _update_module_button(btn: Button, type: String, metal: int) -> void:
	var cost: int = ResourceManager.get_current_module_cost(type)
	var price_label: Label = btn.get_node("V/Price") as Label
	price_label.text = "%d +" % cost
	btn.disabled = metal < cost

	if btn.disabled:
		price_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	else:
		price_label.add_theme_color_override("font_color", Color(0.941, 0.816, 0.125))


func _on_core_plaque_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var upgrade_id: String = _get_active_upgrade_id()
		if upgrade_id.is_empty():
			return
		if _core_upgrade != null and _core_upgrade.try_purchase(upgrade_id):
			_refresh_ui()

func _on_btn_shop_pressed() -> void:
	if _is_game_finished: return
	AudioManager.play_ui_open()
	_set_shop_open(not _is_shop_open(), true)

func _set_shop_open(value: bool, sync_pause: bool) -> void:
	if _shop_state != null:
		_shop_state.set_shop_open(value, sync_pause, shop_overlay)


func _is_shop_open() -> bool:
	return _shop_state != null and _shop_state.is_shop_open()

func _on_btn_shop_exit_pressed() -> void:
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


func _on_btn_hull_pressed() -> void: _request_build(Constants.MODULE_HULL)
func _on_btn_reactor_pressed() -> void: _request_build(Constants.MODULE_REACTOR)
func _on_btn_collector_pressed() -> void: _request_build(Constants.MODULE_COLLECTOR)
func _on_btn_turret_pressed() -> void: _request_build(Constants.MODULE_TURRET)

func _request_build(type: String) -> void:
	if _is_game_finished: return
	GameEvents.build_requested.emit(type, Vector2.ZERO)
	_set_shop_open(false, false) # Закрываем для выбора места

func _on_game_finished(outcome: String, _reason: String) -> void:
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
	if _tutorial_focus == null:
		return
	_tutorial_focus.register_targets({
		"shop_button": btn_shop,
		"hull": btn_hull,
		"reactor": btn_reactor,
		"collector": btn_collector,
		"turret": btn_turret,
		"core": core_plaque,
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
			if not _is_shop_open():
				_on_btn_shop_pressed()
		"buy_hull":
			if _is_shop_open() and not btn_hull.disabled:
				_on_btn_hull_pressed()

func _get_focused_target_id() -> String:
	if _tutorial_focus == null:
		return ""
	return _tutorial_focus.get_focused_target_id()
