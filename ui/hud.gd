extends CanvasLayer

@onready var metal_label = $TopPanel/MetalLabel
@onready var size_label = $TopPanel/SizeLabel

@onready var hull_btn = $BottomPanel/HBox/HullBtn
@onready var cargo_btn = $BottomPanel/HBox/CargoBtn
@onready var collect_btn = $BottomPanel/HBox/CollectBtn

signal build_mode_selected(type)

func _ready():
	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.ship_updated.connect(_on_ship_updated)
	_update_ui()

func _update_ui():
	# We can't easily get the ship size from here without a direct reference or another signal.
	# Let's assume size update happens via signal.
	pass

func _on_resource_changed(type, current, limit):
	if type == "metal":
		metal_label.text = "МЕТАЛЛ: %d / %d" % [current, limit]
		hull_btn.disabled = current < 3
		cargo_btn.disabled = current < 5
		collect_btn.disabled = current < 10

func _on_ship_updated():
	# For now, let's just emit build mode signals
	pass

func _on_hull_btn_pressed():
	build_mode_selected.emit(4)

func _on_cargo_btn_pressed():
	build_mode_selected.emit(2)

func _on_collect_btn_pressed():
	build_mode_selected.emit(3)
