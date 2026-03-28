extends CanvasLayer

@onready var metal_label: Label = %MetalLabel
@onready var metal_bar: ProgressBar = %MetalBar
@onready var btn_reactor: Button = %BtnReactor
@onready var btn_collector: Button = %BtnCollector
@onready var btn_hull: Button = %BtnHull
@onready var btn_turret: Button = %BtnTurret
@onready var btn_shop: Button = %BtnShop
@onready var bottom_panel: HBoxContainer = %BottomPanel
@onready var end_overlay: ColorRect = %EndOverlay
@onready var end_title_label: Label = %EndTitleLabel
@onready var end_reason_label: Label = %EndReasonLabel
@onready var btn_restart: Button = %BtnRestart

var _is_game_finished: bool = false

func _ready() -> void:
	GameEvents.resource_changed.connect(_on_resource_changed)
	# Закрываем меню, когда модуль успешно построен
	GameEvents.module_built.connect(_on_module_built)
	if GameEvents.has_signal("game_finished"):
		GameEvents.game_finished.connect(_on_game_finished)
	
	btn_reactor.pressed.connect(_on_btn_reactor_pressed)
	btn_collector.pressed.connect(_on_btn_collector_pressed)
	btn_hull.pressed.connect(_on_btn_hull_pressed)
	btn_turret.pressed.connect(_on_btn_turret_pressed)
	btn_shop.pressed.connect(_on_btn_shop_pressed)
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	_apply_button_texts()
	_sync_resource_ui(ResourceManager.metal, ResourceManager.max_metal, false)
	
	bottom_panel.visible = false
	end_overlay.visible = false
	_update_buttons(ResourceManager.metal)
	
	print("MainUI Initialized")

func _on_resource_changed(type: String, new_total: int) -> void:
	if _is_game_finished:
		return
	if type == "metal":
		_sync_resource_ui(new_total, ResourceManager.max_metal, true)
		_update_buttons(new_total)


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

	btn_hull.disabled = current_metal < Constants.get_module_cost(Constants.MODULE_HULL)
	btn_reactor.disabled = current_metal < Constants.get_module_cost(Constants.MODULE_REACTOR)
	btn_collector.disabled = current_metal < Constants.get_module_cost(Constants.MODULE_COLLECTOR)
	btn_turret.disabled = current_metal < Constants.get_module_cost(Constants.MODULE_TURRET)


func _apply_button_texts() -> void:
	btn_hull.text = " Корпус \n(%d Металла) " % Constants.get_module_cost(Constants.MODULE_HULL)
	btn_reactor.text = " Реактор \n(%d Металла) " % Constants.get_module_cost(Constants.MODULE_REACTOR)
	btn_collector.text = " Сборщик \n(%d Металла) " % Constants.get_module_cost(Constants.MODULE_COLLECTOR)
	btn_turret.text = " Турель \n(%d Металла) " % Constants.get_module_cost(Constants.MODULE_TURRET)

func _on_btn_shop_pressed() -> void:
	if _is_game_finished:
		return
	AudioManager.play_ui_open()
	bottom_panel.visible = !bottom_panel.visible

func _on_module_built(_type: String, _pos: Vector2) -> void:
	if _is_game_finished:
		return
	# Закрываем панель после постройки
	bottom_panel.visible = false

func _on_btn_hull_pressed() -> void:
	if _is_game_finished:
		return
	AudioManager.play_ui_click()
	GameEvents.build_requested.emit(Constants.MODULE_HULL, Vector2.ZERO)
	# Можно закрыть сразу после выбора, чтобы не мешать кликать по сетке
	bottom_panel.visible = false

func _on_btn_reactor_pressed() -> void:
	if _is_game_finished:
		return
	AudioManager.play_ui_click()
	GameEvents.build_requested.emit(Constants.MODULE_REACTOR, Vector2.ZERO)
	bottom_panel.visible = false

func _on_btn_collector_pressed() -> void:
	if _is_game_finished:
		return
	AudioManager.play_ui_click()
	GameEvents.build_requested.emit(Constants.MODULE_COLLECTOR, Vector2.ZERO)
	bottom_panel.visible = false


func _on_btn_turret_pressed() -> void:
	if _is_game_finished:
		return
	AudioManager.play_ui_click()
	GameEvents.build_requested.emit(Constants.MODULE_TURRET, Vector2.ZERO)
	bottom_panel.visible = false


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
	var tree := get_tree()
	if tree != null:
		tree.reload_current_scene()
