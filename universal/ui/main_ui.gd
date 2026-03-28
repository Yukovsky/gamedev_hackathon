extends CanvasLayer

@onready var metal_label: Label = %MetalLabel
@onready var metal_bar: ProgressBar = %MetalBar
@onready var btn_reactor: Button = %BtnReactor
@onready var btn_collector: Button = %BtnCollector
@onready var btn_hull: Button = %BtnHull
@onready var btn_turret: Button = %BtnTurret
@onready var btn_shop: Button = %BtnShop
@onready var btn_bgm_toggle: Button = %BtnBgmToggle
@onready var btn_shop_exit: Button = %BtnShopExit
@onready var bottom_panel: Control = %BottomPanel
@onready var end_overlay: ColorRect = %EndOverlay
@onready var end_title_label: Label = %EndTitleLabel
@onready var end_reason_label: Label = %EndReasonLabel
@onready var btn_restart: Button = %BtnRestart

var _is_game_finished: bool = false
@onready var upgrades_panel: VBoxContainer = %UpgradesPanel
@onready var upgrades_list: VBoxContainer = %UpgradesList

var _shop_open: bool = false
var _upgrade_button_by_id: Dictionary = {}

func _ready() -> void:
	# UI должна оставаться интерактивной, когда дерево на паузе.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_static_font_overrides()

	GameEvents.resource_changed.connect(_on_resource_changed)
	# Закрываем меню, когда модуль успешно построен
	GameEvents.module_built.connect(_on_module_built)
	if GameEvents.has_signal("game_finished"):
		GameEvents.game_finished.connect(_on_game_finished)
	GameEvents.build_mode_cancelled.connect(_on_build_mode_cancelled)
	GameEvents.upgrade_purchased.connect(_on_upgrade_purchased)
	
	btn_reactor.pressed.connect(_on_btn_reactor_pressed)
	btn_collector.pressed.connect(_on_btn_collector_pressed)
	btn_hull.pressed.connect(_on_btn_hull_pressed)
	btn_turret.pressed.connect(_on_btn_turret_pressed)
	btn_shop.pressed.connect(_on_btn_shop_pressed)
	btn_bgm_toggle.pressed.connect(_on_btn_bgm_toggle_pressed)
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	btn_shop_exit.pressed.connect(_on_btn_shop_exit_pressed)
	_build_upgrade_buttons()
	_apply_button_texts()
	_sync_resource_ui(ResourceManager.metal, ResourceManager.max_metal, false)
	
	_set_shop_open(false, false)
	end_overlay.visible = false
	_update_buttons(ResourceManager.metal)
	_refresh_upgrade_buttons(ResourceManager.metal)
	_update_bgm_button()
	
	print("MainUI Initialized")


func _apply_static_font_overrides() -> void:
	# В некоторых сборках безопаснее задавать размеры через API, а не через serialized theme_override_font_sizes.
	btn_shop.add_theme_font_size_override("font_size", 64)
	btn_shop_exit.add_theme_font_size_override("font_size", 42)
	btn_hull.add_theme_font_size_override("font_size", 48)
	btn_reactor.add_theme_font_size_override("font_size", 48)
	btn_collector.add_theme_font_size_override("font_size", 48)
	btn_turret.add_theme_font_size_override("font_size", 48)
	btn_restart.add_theme_font_size_override("font_size", 46)

func _on_resource_changed(type: String, new_total: int) -> void:
	if _is_game_finished:
		return
	if type == "metal":
		_sync_resource_ui(new_total, ResourceManager.max_metal, true)
		_update_buttons(new_total)
		_refresh_upgrade_buttons(new_total)


func _sync_resource_ui(current_total: int, max_total: int, animate: bool) -> void:
	metal_label.text = "Металл: %d / %d" % [current_total, max_total]
	metal_bar.min_value = 0
	metal_bar.max_value = max_total
	metal_bar.value = current_total
	if animate:
		_flash_label(metal_label)

func _flash_label(label: Label) -> void:
	var tween = create_tween()
	label.modulate = Color(0.5, 1.5, 0.5)
	tween.tween_property(label, "modulate", Color.WHITE, 0.3)

func _update_buttons(current_metal: int) -> void:
	if _is_game_finished:
		btn_hull.disabled = true
		btn_reactor.disabled = true
		btn_collector.disabled = true
		btn_turret.disabled = true
		btn_shop.disabled = true
		return

	btn_hull.disabled = current_metal < ResourceManager.get_current_module_cost(Constants.MODULE_HULL)
	btn_reactor.disabled = current_metal < ResourceManager.get_current_module_cost(Constants.MODULE_REACTOR)
	btn_collector.disabled = current_metal < ResourceManager.get_current_module_cost(Constants.MODULE_COLLECTOR)
	btn_turret.disabled = current_metal < ResourceManager.get_current_module_cost(Constants.MODULE_TURRET)


func _build_upgrade_buttons() -> void:
	for child in upgrades_list.get_children():
		child.queue_free()

	_upgrade_button_by_id.clear()
	for upgrade_id in UpgradeManager.get_upgrade_ids():
		var button: Button = Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 36)
		button.theme = btn_shop.theme
		button.add_theme_stylebox_override("normal", btn_shop.get_theme_stylebox("normal"))
		button.add_theme_stylebox_override("hover", btn_shop.get_theme_stylebox("hover"))
		button.add_theme_stylebox_override("pressed", btn_shop.get_theme_stylebox("pressed"))
		button.add_theme_stylebox_override("disabled", btn_shop.get_theme_stylebox("disabled"))
		button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade_id))
		upgrades_list.add_child(button)
		_upgrade_button_by_id[upgrade_id] = button


func _apply_button_texts() -> void:
	btn_hull.text = " Корпус \n(%d Металла) " % ResourceManager.get_current_module_cost(Constants.MODULE_HULL)
	btn_reactor.text = " Реактор \n(%d Металла) " % ResourceManager.get_current_module_cost(Constants.MODULE_REACTOR)
	btn_collector.text = " Сборщик \n(%d Металла) " % ResourceManager.get_current_module_cost(Constants.MODULE_COLLECTOR)
	btn_turret.text = " Турель \n(%d Металла) " % ResourceManager.get_current_module_cost(Constants.MODULE_TURRET)

func _on_btn_shop_pressed() -> void:
	if _is_game_finished:
		return
	AudioManager.play_ui_open()
	_set_shop_open(not _shop_open, true)

func _on_module_built(_type: String, _pos: Vector2) -> void:
	if _is_game_finished:
		return
	# Закрываем магазин после успешной постройки и снимаем паузу.
	_set_shop_open(false, true)
	_apply_button_texts()
	_update_buttons(ResourceManager.metal)
	_refresh_upgrade_buttons(ResourceManager.metal)


func _on_upgrade_purchased(_upgrade_id: String, _new_level: int) -> void:
	_set_shop_open(false, true)
	_refresh_upgrade_buttons(ResourceManager.metal)


func _update_bgm_button() -> void:
	if AudioManager.is_bgm_enabled():
		btn_bgm_toggle.text = "BGM: ON"
		btn_bgm_toggle.add_theme_color_override("font_color", Color(0.8, 1, 0.3))
	else:
		btn_bgm_toggle.text = "BGM: OFF"
		btn_bgm_toggle.add_theme_color_override("font_color", Color(1, 0.5, 0.5))

func _on_btn_bgm_toggle_pressed() -> void:
	AudioManager.play_ui_click()
	var enabled := AudioManager.toggle_bgm()
	_update_bgm_button()
	if enabled:
		AudioManager.play_ui_open()

func _on_build_mode_cancelled(_module_type: String) -> void:
	# Режим постройки отменен: снимаем паузу, магазин уже скрыт.
	get_tree().paused = false


func _on_upgrade_button_pressed(upgrade_id: String) -> void:
	if UpgradeManager.purchase(upgrade_id):
		return
	_refresh_upgrade_buttons(ResourceManager.metal)


func _refresh_upgrade_buttons(current_metal: int) -> void:
	for upgrade_id in _upgrade_button_by_id.keys():
		var button: Button = _upgrade_button_by_id[upgrade_id]
		if button == null:
			continue

		var current_level: int = UpgradeManager.get_upgrade_level(upgrade_id)
		var max_level: int = UpgradeManager.get_upgrade_max_level(upgrade_id)
		if current_level >= max_level:
			button.text = "%s\nУровень %d/%d (MAX)" % [UpgradeManager.get_upgrade_name(upgrade_id), current_level, max_level]
			button.disabled = true
			continue

		var next_cost: int = UpgradeManager.get_upgrade_next_cost(upgrade_id)
		button.text = "%s\nУровень %d/%d -> %d Металла" % [
			UpgradeManager.get_upgrade_name(upgrade_id),
			current_level,
			max_level,
			next_cost,
		]
		button.disabled = current_metal < next_cost


func _set_shop_open(value: bool, sync_pause: bool) -> void:
	_shop_open = value
	bottom_panel.visible = value
	upgrades_panel.visible = value
	btn_shop_exit.visible = value

	if sync_pause:
		get_tree().paused = value


func _on_btn_shop_exit_pressed() -> void:
	_set_shop_open(false, true)

func _on_btn_hull_pressed() -> void:
	if _is_game_finished:
		return
	AudioManager.play_ui_click()
	GameEvents.build_requested.emit(Constants.MODULE_HULL, Vector2.ZERO)
	_hide_shop_for_build_mode()

func _on_btn_reactor_pressed() -> void:
	if _is_game_finished:
		return
	AudioManager.play_ui_click()
	GameEvents.build_requested.emit(Constants.MODULE_REACTOR, Vector2.ZERO)
	_hide_shop_for_build_mode()

func _on_btn_collector_pressed() -> void:
	if _is_game_finished:
		return
	AudioManager.play_ui_click()
	GameEvents.build_requested.emit(Constants.MODULE_COLLECTOR, Vector2.ZERO)
	_hide_shop_for_build_mode()


func _hide_shop_for_build_mode() -> void:
	_shop_open = false
	bottom_panel.visible = false
	upgrades_panel.visible = false
	btn_shop_exit.visible = false


func _on_btn_turret_pressed() -> void:
	if _is_game_finished:
		return
	AudioManager.play_ui_click()
	GameEvents.build_requested.emit(Constants.MODULE_TURRET, Vector2.ZERO)
	_hide_shop_for_build_mode()


func _on_game_finished(outcome: String, reason: String) -> void:
	if _is_game_finished:
		return

	_is_game_finished = true
	bottom_panel.visible = false
	_update_buttons(ResourceManager.metal)

	end_overlay.visible = true
	if outcome == "win":
		end_title_label.text = "ПОБЕДА"
		end_reason_label.text = "Ты построил 4 реактора и вывел станцию на максимальную мощность."
	else:
		end_title_label.text = "GAME OVER"
		if reason == "core_eaten_by_raiders":
			end_reason_label.text = "Налётчики съели ядро. Корабль потерян."
		else:
			end_reason_label.text = "Ядро разрушено. Миссия провалена."


func _on_btn_restart_pressed() -> void:
	AudioManager.play_ui_open()
	upgrades_panel.visible = false
	btn_shop_exit.visible = false
	get_tree().paused = false
	AudioManager.set_bgm_enabled(true)
	_update_bgm_button()

	var tree := get_tree()
	if tree != null:
		# перезагрузка сцены сохранит global singleton-ы, но внутренняя логика ResourceManager/UpgradeManager остаётся
		if ResourceManager.has_method("reset"):
			ResourceManager.reset()
		if UpgradeManager.has_method("reset"):
			UpgradeManager.reset()
		tree.reload_current_scene()
