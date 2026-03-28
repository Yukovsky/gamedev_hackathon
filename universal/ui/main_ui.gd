extends CanvasLayer

@onready var metal_label: Label = %MetalLabel
@onready var btn_reactor: Button = %BtnReactor
@onready var btn_collector: Button = %BtnCollector
@onready var btn_hull: Button = %BtnHull
@onready var btn_shop: Button = %BtnShop
@onready var bottom_panel: HBoxContainer = %BottomPanel

# Цены модулей
const COST_HULL = 5
const COST_GENERATOR = 15
const COST_COLLECTOR = 25

func _ready() -> void:
	GameEvents.resource_changed.connect(_on_resource_changed)
	
	btn_reactor.pressed.connect(_on_btn_reactor_pressed)
	btn_collector.pressed.connect(_on_btn_collector_pressed)
	btn_hull.pressed.connect(_on_btn_hull_pressed)
	btn_shop.pressed.connect(_on_btn_shop_pressed)
	
	bottom_panel.visible = false
	_update_buttons(0)
	
	print("MainUI Initialized (No Energy Mode)")

func _on_resource_changed(type: String, new_total: int, max_total: int) -> void:
	if type == "metal":
		metal_label.text = "Металл: %d / %d" % [new_total, max_total]
		metal_bar.max_value = max_total
		metal_bar.value = new_total
		_update_buttons(new_total)
		_flash_label(metal_label)

func _on_btn_reactor_pressed() -> void:
	GameEvents.build_requested.emit(Constants.MODULE_REACTOR, Vector2.ZERO)
	print("Requested Reactor")

func _on_btn_collector_pressed() -> void:
	GameEvents.build_requested.emit(Constants.MODULE_COLLECTOR, Vector2.ZERO)
	print("Requested Collector")
