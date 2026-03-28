extends Node
class_name ResourceGeneratorComponent

signal resource_generated(resource_type: String, amount: int)

@export var resource_type: String = "metal"
@export var amount_per_tick: int = 1
@export var tick_interval_sec: float = 1.0
@export var auto_start: bool = true

var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = tick_interval_sec
	_timer.timeout.connect(_on_tick)
	add_child(_timer)

	if auto_start:
		start()


func start() -> void:
	if _timer != null and _timer.is_stopped():
		_timer.start()


func stop() -> void:
	if _timer != null and not _timer.is_stopped():
		_timer.stop()


func _on_tick() -> void:
	if amount_per_tick <= 0:
		return
	resource_generated.emit(resource_type, amount_per_tick)
