extends CanvasLayer

@onready var metal_label: Label = %MetalLabel
@onready var btn_storage: Button = %BtnStorage
@onready var btn_collector: Button = %BtnCollector

func _ready() -> void:
	# Программист 3: Логика UI (HUD, меню, экран победы/поражения)
	GameEvents.resource_changed.connect(_on_resource_changed)
	
	btn_storage.pressed.connect(_on_btn_storage_pressed)
	btn_collector.pressed.connect(_on_btn_collector_pressed)
	
	print("MainUI Initialized")

func _on_resource_changed(type: String, new_total: int, max_total: int) -> void:
	if type == "metal":
		metal_label.text = "Металл: %d / %d" % [new_total, max_total]
		
		# Visual feedback: flash label color
		var tween = create_tween()
		metal_label.modulate = Color(0.5, 1.5, 0.5) # Bright green flash
		tween.tween_property(metal_label, "modulate", Color.WHITE, 0.3)

# Temporary test: tap anywhere to simulate gathering metal
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		GameEvents.garbage_clicked.emit(1)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GameEvents.garbage_clicked.emit(1)

func _on_btn_storage_pressed() -> void:
	GameEvents.build_requested.emit("storage", Vector2.ZERO) # Placeholder pos
	print("Requested Storage")

func _on_btn_collector_pressed() -> void:
	GameEvents.build_requested.emit("collector", Vector2.ZERO) # Placeholder pos
	print("Requested Collector")
