extends CanvasLayer

@onready var metal_label = $TopPanel/MetalLabel
@onready var size_label = $TopPanel/SizeLabel

@onready var hull_btn = $BottomPanel/HBox/HullBtn
@onready var cargo_btn = $BottomPanel/HBox/CargoBtn
@onready var collect_btn = $BottomPanel/HBox/CollectBtn

signal build_mode_selected(type)

func _ready():
	GameManager.metal_changed.connect(_on_metal_changed)
	GameManager.ship_updated.connect(_on_ship_updated)
	_update_ui()

func _update_ui():
	metal_label.text = "METAL: %d / %d" % [GameManager.metal, GameManager.max_metal]
	
	var min_x = 999
	var max_x = -999
	var min_y = 999
	var max_y = -999
	for p in GameManager.ship_modules:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	
	var w = max_x - min_x + 1
	var h = max_y - min_y + 1
	size_label.text = "SIZE: %d x %d" % [w, h]
	
	hull_btn.disabled = GameManager.metal < 3
	cargo_btn.disabled = GameManager.metal < 5
	collect_btn.disabled = GameManager.metal < 10

func _on_metal_changed(_c, _l):
	_update_ui()

func _on_ship_updated():
	_update_ui()

func _on_hull_btn_pressed():
	build_mode_selected.emit(4) # HULL

func _on_cargo_btn_pressed():
	build_mode_selected.emit(2) # CARGO

func _on_collect_btn_pressed():
	build_mode_selected.emit(3) # COLLECTOR
