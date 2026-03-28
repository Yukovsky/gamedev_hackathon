extends Node2D

@export_group("Spawn Rules")
@export var spawn_interval_sec: float = 1.0
@export_range(0.0, 1.0, 0.01) var spawn_chance: float = 0.8
@export var max_debris_on_screen: int = 20

@export_group("Spawn Bounds")
@export var spawn_offset_y_px: float = 120.0
@export var despawn_offset_y_px: float = 120.0
@export var spawn_margin_x_px: float = 45.0

@export_group("Debris Scene")
@export var debris_scene: PackedScene = preload("res://entities/debris/debris.tscn")

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_timer: Timer
var _active_debris: Array[Node2D] = []


func _ready() -> void:
	_rng.randomize()

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval_sec
	_spawn_timer.one_shot = false
	_spawn_timer.autostart = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)


func _process(_delta: float) -> void:
	_cleanup_offscreen_debris()


func _on_spawn_timer_timeout() -> void:
	if _active_debris.size() >= max_debris_on_screen:
		return

	if _rng.randf() > spawn_chance:
		return

	_spawn_debris()


func _spawn_debris() -> void:
	if debris_scene == null:
		return

	var debris: Node2D = debris_scene.instantiate() as Node2D
	if debris == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var min_x: float = spawn_margin_x_px
	var max_x: float = max(spawn_margin_x_px, viewport_size.x - spawn_margin_x_px)
	var spawn_x: float = _rng.randf_range(min_x, max_x)

	debris.global_position = Vector2(spawn_x, -spawn_offset_y_px)
	debris.set("movement_direction", Vector2.DOWN)
	debris.set("debris_type", _rng.randi_range(0, 2))

	add_child(debris)
	_active_debris.append(debris)
	debris.tree_exited.connect(_on_debris_tree_exited.bind(debris))


func _cleanup_offscreen_debris() -> void:
	var viewport_height: float = get_viewport_rect().size.y
	for debris in _active_debris:
		if not is_instance_valid(debris):
			continue

		if debris.global_position.y > viewport_height + despawn_offset_y_px:
			debris.queue_free()


func _on_debris_tree_exited(debris: Node2D) -> void:
	_active_debris.erase(debris)
