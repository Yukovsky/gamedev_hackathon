extends Node2D

enum DebrisType {
	TRASH_1,
	TRASH_2,
	TRASH_3,
}

signal collected(amount: int, debris_type: DebrisType, source: String)

# Explicit balancing variables for designers (Godot Inspector -> Debris Stats)
@export_group("Debris Stats")
@export var metal_reward_trash_1: int = 17
@export var metal_reward_trash_2: int = 13
@export var metal_reward_trash_3: int = 20
@export var movement_speed_px_per_sec: float = 500.0
@export var unit_size_px: Vector2 = Vector2(140.0, 140.0)
@export var movement_direction: Vector2 = Vector2.DOWN

@export_group("Debris Pixel Burst")
@export var burst_enabled: bool = true
@export var burst_pixel_count: int = 18
@export var burst_pixel_size_px: float = 5.0
@export var burst_radius_px: float = 72.0
@export var burst_duration_sec: float = 0.38
@export var min_rotation_speed_deg_per_sec: float = 30.0
@export var max_rotation_speed_deg_per_sec: float = 180.0

@export_group("Debris Visual")
@export var debris_type: DebrisType = DebrisType.TRASH_1:
	set(value):
		debris_type = value
		_apply_visual()

@export var trash_texture_1: Texture2D = preload("res://assets/sprites/trash-1.png")
@export var trash_texture_2: Texture2D = preload("res://assets/sprites/trash-2.png")
@export var trash_texture_3: Texture2D = preload("res://assets/sprites/trash-3.png")

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _clickable: Area2D = $ClickableComponent
@onready var _collision_shape: CollisionShape2D = $ClickableComponent/CollisionShape2D

var _is_collected: bool = false
var _collector_mark_owner_id: int = 0
var _rotation_speed_rad_per_sec: float = 0.0


func _ready() -> void:
	add_to_group("debris")
	_apply_visual()
	_apply_unit_size()
	_setup_random_rotation()
	if _clickable.has_signal("clicked"):
		_clickable.connect("clicked", _on_clicked)


func _process(delta: float) -> void:
	position += _get_movement_vector() * movement_speed_px_per_sec * delta
	rotation += _rotation_speed_rad_per_sec * delta


func auto_collect() -> void:
	collect("collector")


func can_be_marked_by(collector_id: int) -> bool:
	if _is_collected:
		return false
	return _collector_mark_owner_id == 0 or _collector_mark_owner_id == collector_id


func mark_by_collector(collector_id: int) -> bool:
	if not can_be_marked_by(collector_id):
		return false

	_collector_mark_owner_id = collector_id
	return true


func unmark_by_collector(collector_id: int) -> void:
	if _collector_mark_owner_id == collector_id:
		_collector_mark_owner_id = 0


func is_marked_by_collector(collector_id: int) -> bool:
	return _collector_mark_owner_id == collector_id


func collect_by_collector(collector_id: int) -> bool:
	if _is_collected:
		return false

	if _collector_mark_owner_id != 0 and _collector_mark_owner_id != collector_id:
		return false

	collect("collector")
	return true


func collect_if_in_radius(origin: Vector2, radius_px: float) -> bool:
	if _is_collected:
		return false

	if global_position.distance_to(origin) > radius_px:
		return false

	collect("collector")
	return true


func collect(source: String = "click") -> void:
	if _is_collected:
		return

	_is_collected = true
	_collector_mark_owner_id = 0
	if burst_enabled:
		_spawn_pixel_burst()
	var amount: int = _get_metal_reward()
	GameEvents.garbage_clicked.emit(amount)
	collected.emit(amount, debris_type, source)
	queue_free()


func _on_clicked() -> void:
	collect("click")


func _get_metal_reward() -> int:
	if UpgradeManager != null:
		return UpgradeManager.get_metal_reward_for_debris(int(debris_type))

	match debris_type:
		DebrisType.TRASH_1:
			return metal_reward_trash_1
		DebrisType.TRASH_2:
			return metal_reward_trash_2
		DebrisType.TRASH_3:
			return metal_reward_trash_3
		_:
			return metal_reward_trash_1


func _get_movement_vector() -> Vector2:
	if movement_direction == Vector2.ZERO:
		return Vector2.DOWN
	return movement_direction.normalized()


func _apply_visual() -> void:
	if _sprite == null:
		return

	match debris_type:
		DebrisType.TRASH_1:
			_sprite.texture = trash_texture_1
		DebrisType.TRASH_2:
			_sprite.texture = trash_texture_2
		DebrisType.TRASH_3:
			_sprite.texture = trash_texture_3
		_:
			_sprite.texture = trash_texture_1

	_fit_sprite_to_unit_size()


func _apply_unit_size() -> void:
	if _collision_shape == null:
		return

	var shape: Shape2D = _collision_shape.shape
	if shape is RectangleShape2D:
		(shape as RectangleShape2D).size = unit_size_px

	_fit_sprite_to_unit_size()


func _fit_sprite_to_unit_size() -> void:
	if _sprite == null or _sprite.texture == null:
		return

	var texture_size: Vector2 = _sprite.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	_sprite.scale = Vector2(unit_size_px.x / texture_size.x, unit_size_px.y / texture_size.y)


func _spawn_pixel_burst() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var burst_root := Node2D.new()
	burst_root.global_position = global_position
	parent_node.add_child(burst_root)

	var color: Color = _get_burst_color()
	for _i in range(max(1, burst_pixel_count)):
		var pixel := Polygon2D.new()
		var size: float = burst_pixel_size_px * randf_range(0.7, 1.25)
		pixel.polygon = PackedVector2Array([
			Vector2(-size, -size),
			Vector2(size, -size),
			Vector2(size, size),
			Vector2(-size, size),
		])
		pixel.color = color.lerp(Color.WHITE, randf() * 0.25)
		pixel.position = Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
		burst_root.add_child(pixel)

		var angle: float = randf() * TAU
		var distance: float = randf_range(burst_radius_px * 0.35, burst_radius_px)
		var target: Vector2 = Vector2.RIGHT.rotated(angle) * distance

		var tw: Tween = burst_root.create_tween()
		tw.tween_property(pixel, "position", target, burst_duration_sec)
		tw.parallel().tween_property(pixel, "rotation", randf_range(-2.4, 2.4), burst_duration_sec)
		tw.parallel().tween_property(pixel, "modulate:a", 0.0, burst_duration_sec)
		tw.tween_callback(pixel.queue_free)

	var cleanup_tw: Tween = burst_root.create_tween()
	cleanup_tw.tween_interval(burst_duration_sec + 0.08)
	cleanup_tw.tween_callback(burst_root.queue_free)


func _get_burst_color() -> Color:
	match debris_type:
		DebrisType.TRASH_1:
			return Color(0.75, 0.85, 1.0, 1.0)
		DebrisType.TRASH_2:
			return Color(0.75, 1.0, 0.78, 1.0)
		DebrisType.TRASH_3:
			return Color(1.0, 0.84, 0.64, 1.0)
		_:
			return Color(0.85, 0.85, 0.95, 1.0)


func _setup_random_rotation() -> void:
	var min_speed: float = min(min_rotation_speed_deg_per_sec, max_rotation_speed_deg_per_sec)
	var max_speed: float = max(min_rotation_speed_deg_per_sec, max_rotation_speed_deg_per_sec)
	var speed_deg: float = randf_range(min_speed, max_speed)
	if randf() < 0.5:
		speed_deg *= -1.0

	_rotation_speed_rad_per_sec = deg_to_rad(speed_deg)
