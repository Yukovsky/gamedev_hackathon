extends CanvasLayer

@onready var metal_label: Label = %MetalLabel
@onready var btn_reactor: Button = %BtnReactor
@onready var btn_collector: Button = %BtnCollector

func _ready() -> void:
	# Программист 3: Логика UI (HUD, меню, экран победы/поражения)
	GameEvents.resource_changed.connect(_on_resource_changed)
	
	btn_reactor.pressed.connect(_on_btn_reactor_pressed)
	btn_collector.pressed.connect(_on_btn_collector_pressed)
	
	print("MainUI Initialized")

func _on_resource_changed(type: String, new_total: int) -> void:
	if type == "metal":
		metal_label.text = "Metal: %d" % new_total

func _on_btn_reactor_pressed() -> void:
	GameEvents.build_requested.emit(Constants.MODULE_REACTOR, Vector2.ZERO)
	print("Requested Reactor")

func _on_btn_collector_pressed() -> void:
	GameEvents.build_requested.emit(Constants.MODULE_COLLECTOR, Vector2.ZERO)
	print("Requested Collector")
