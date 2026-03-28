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
@export var movement_speed_px_per_sec: float = 90.0
@export var unit_size_px: Vector2 = Vector2(90.0, 90.0)
@export var movement_direction: Vector2 = Vector2.DOWN

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


func _ready() -> void:
	add_to_group("debris")
	_apply_visual()
	_apply_unit_size()
	if _clickable.has_signal("clicked"):
		_clickable.connect("clicked", _on_clicked)


func _process(delta: float) -> void:
	position += _get_movement_vector() * movement_speed_px_per_sec * delta


func auto_collect() -> void:
	collect("collector")


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
	var amount: int = _get_metal_reward()
	GameEvents.garbage_clicked.emit(amount)
	collected.emit(amount, debris_type, source)
	queue_free()


func _on_clicked() -> void:
	collect("click")


func _get_metal_reward() -> int:
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
