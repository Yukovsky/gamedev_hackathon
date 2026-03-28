extends Node2D
class_name TempCombatVfx

@export var spawn_color: Color = Color(1.0, 0.25, 0.25, 0.9)
@export var bite_color: Color = Color(1.0, 0.75, 0.25, 0.95)
@export var destroy_color: Color = Color(1.0, 0.15, 0.1, 0.95)


func set_palette(primary_color: Color, secondary_color: Color) -> void:
	# Подбираем оттенки эффекта из цветов конкретного налетчика.
	spawn_color = primary_color.lerp(Color.WHITE, 0.12)
	bite_color = secondary_color.lerp(primary_color, 0.35)
	destroy_color = primary_color.lerp(Color.BLACK, 0.18)


func play_spawn(position_world: Vector2) -> void:
	_spawn_ring(position_world, 18.0, 54.0, 0.22, spawn_color)


func play_bite(position_world: Vector2) -> void:
	_spawn_ring(position_world, 10.0, 38.0, 0.14, bite_color)


func play_destroy(position_world: Vector2) -> void:
	_spawn_ring(position_world, 12.0, 76.0, 0.28, destroy_color)
	_spawn_spark(position_world, destroy_color)


func _spawn_ring(position_world: Vector2, start_radius: float, end_radius: float, duration: float, color: Color) -> void:
	var ring: Polygon2D = Polygon2D.new()
	ring.polygon = _build_circle_polygon(start_radius, 20)
	ring.color = color
	ring.set_as_top_level(true)
	add_child(ring)
	ring.global_position = position_world

	var tween: Tween = create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE * (end_radius / max(1.0, start_radius)), duration)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, duration)
	tween.tween_callback(ring.queue_free)


func _spawn_spark(position_world: Vector2, color: Color) -> void:
	var sparks: int = 5
	for i in range(sparks):
		var p: Polygon2D = Polygon2D.new()
		p.polygon = PackedVector2Array([
			Vector2(0, -5),
			Vector2(2, 0),
			Vector2(0, 5),
			Vector2(-2, 0),
		])
		p.color = color
		p.set_as_top_level(true)
		add_child(p)
		p.global_position = position_world

		var angle: float = randf() * TAU
		var distance: float = randf_range(26.0, 52.0)
		var target_pos: Vector2 = position_world + Vector2.RIGHT.rotated(angle) * distance

		var tween: Tween = create_tween()
		tween.tween_property(p, "global_position", target_pos, 0.22)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.22)
		tween.tween_callback(p.queue_free)


func _build_circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var t: float = float(i) / float(segments)
		var angle: float = t * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
