extends Node
class_name RaiderMovementComponent
## Компонент движения рейдера с wobble-эффектом.

signal reached_target(target_position: Vector2)

@export var movement_speed_px_per_sec: float = 285.0
@export var attack_distance_px: float = 96.0
@export var path_wobble_strength: float = 0.22
@export var path_wobble_frequency_hz: float = 1.1
@export var path_wobble_strength_random_range: float = 0.12
@export var path_wobble_frequency_random_range: float = 0.3
@export var speed_random_range: float = 0.12

var _parent: Node2D
var _movement_time_sec: float = 0.0
var _wobble_phase: float = 0.0
var _runtime_wobble_strength: float = 0.0
var _runtime_wobble_frequency_hz: float = 0.0
var _runtime_speed_multiplier: float = 1.0
var _is_moving: bool = true


func _ready() -> void:
	_parent = get_parent() as Node2D
	randomize_parameters()


func randomize_parameters() -> void:
	_wobble_phase = randf() * TAU
	_runtime_wobble_strength = maxf(0.0, path_wobble_strength + randf_range(-path_wobble_strength_random_range, path_wobble_strength_random_range))
	_runtime_wobble_frequency_hz = maxf(0.05, path_wobble_frequency_hz + randf_range(-path_wobble_frequency_random_range, path_wobble_frequency_random_range))
	_runtime_speed_multiplier = maxf(0.85, 1.0 + randf_range(-speed_random_range, speed_random_range))


func set_moving(enabled: bool) -> void:
	_is_moving = enabled


func is_moving() -> bool:
	return _is_moving


func move_toward_target(target_position: Vector2, delta: float) -> bool:
	## Двигает родителя к цели. Возвращает true, если достиг.
	if _parent == null:
		return false
	
	if not _is_moving:
		return false
	
	_movement_time_sec += delta
	
	var to_target: Vector2 = target_position - _parent.global_position
	var distance: float = to_target.length()
	
	if distance <= attack_distance_px:
		reached_target.emit(target_position)
		return true
	
	if distance > 0.001:
		var speed: float = movement_speed_px_per_sec * _runtime_speed_multiplier
		var move_dir: Vector2 = to_target.normalized()
		var perp_dir: Vector2 = Vector2(-move_dir.y, move_dir.x)
		var wobble: float = sin(_movement_time_sec * TAU * _runtime_wobble_frequency_hz + _wobble_phase)
		var curved_dir: Vector2 = (move_dir + perp_dir * wobble * _runtime_wobble_strength).normalized()
		_parent.global_position += curved_dir * speed * delta
		_parent.rotation = curved_dir.angle()
	
	return false


func get_current_speed() -> float:
	return movement_speed_px_per_sec * _runtime_speed_multiplier


func configure_speed(speed: float) -> void:
	movement_speed_px_per_sec = maxf(10.0, speed)


func configure_attack_distance(distance: float) -> void:
	attack_distance_px = maxf(8.0, distance)
