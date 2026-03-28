extends CanvasLayer

@onready var metal_label: Label = %MetalLabel
@onready var metal_bar: ProgressBar = %MetalBar
@onready var btn_reactor: Button = %BtnReactor
@onready var btn_collector: Button = %BtnCollector
@onready var btn_hull: Button = %BtnHull
@onready var btn_shop: Button = %BtnShop
@onready var bottom_panel: HBoxContainer = %BottomPanel

func _ready() -> void:
	GameEvents.resource_changed.connect(_on_resource_changed)
	# Закрываем меню, когда модуль успешно построен
	GameEvents.module_built.connect(_on_module_built)
	
	btn_reactor.pressed.connect(_on_btn_reactor_pressed)
	btn_collector.pressed.connect(_on_btn_collector_pressed)
	btn_hull.pressed.connect(_on_btn_hull_pressed)
	btn_shop.pressed.connect(_on_btn_shop_pressed)
	_apply_button_texts()
	_sync_resource_ui(ResourceManager.metal, ResourceManager.max_metal, false)
	
	bottom_panel.visible = false
	_update_buttons(ResourceManager.metal)
	
	print("MainUI Initialized")

func _on_resource_changed(type: String, new_total: int) -> void:
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
	btn_hull.disabled = current_metal < ResourceManager.get_current_module_cost(Constants.MODULE_HULL)
	btn_reactor.disabled = current_metal < ResourceManager.get_current_module_cost(Constants.MODULE_REACTOR)
	btn_collector.disabled = current_metal < ResourceManager.get_current_module_cost(Constants.MODULE_COLLECTOR)


func _apply_button_texts() -> void:
	btn_hull.text = " Корпус \n(%d Металла) " % ResourceManager.get_current_module_cost(Constants.MODULE_HULL)
	btn_reactor.text = " Реактор \n(%d Металла) " % ResourceManager.get_current_module_cost(Constants.MODULE_REACTOR)
	btn_collector.text = " Сборщик \n(%d Металла) " % ResourceManager.get_current_module_cost(Constants.MODULE_COLLECTOR)

func _on_btn_shop_pressed() -> void:
	bottom_panel.visible = !bottom_panel.visible

func _on_module_built(_type: String, _pos: Vector2) -> void:
	# Закрываем панель после постройки
	bottom_panel.visible = false
	_apply_button_texts()
	_update_buttons(ResourceManager.metal)

func _on_btn_hull_pressed() -> void:
	GameEvents.build_requested.emit(Constants.MODULE_HULL, Vector2.ZERO)
	# Можно закрыть сразу после выбора, чтобы не мешать кликать по сетке
	bottom_panel.visible = false

func _on_btn_reactor_pressed() -> void:
	GameEvents.build_requested.emit(Constants.MODULE_REACTOR, Vector2.ZERO)
	bottom_panel.visible = false

func _on_btn_collector_pressed() -> void:
	GameEvents.build_requested.emit(Constants.MODULE_COLLECTOR, Vector2.ZERO)
	bottom_panel.visible = false
