extends Node
class_name ViewportBoundsComponent
## Компонент ограничения позиции родителя границами viewport.
## Добавьте как дочерний узел к Node2D для автоматического clamp.

@export var enabled: bool = true
@export var margin_x: float = 0.0
@export var margin_top: float = 0.0
@export var margin_bottom: float = 0.0
@export var half_size: Vector2 = Vector2(64.0, 64.0)

var _parent: Node2D


func _ready() -> void:
	_parent = get_parent() as Node2D


func _process(_delta: float) -> void:
	if not enabled:
		return
	if _parent == null:
		return
	
	clamp_parent_position()


func clamp_parent_position() -> void:
	if _parent == null:
		return
	
	var viewport_size: Vector2 = _parent.get_viewport_rect().size
	
	var min_x: float = half_size.x + margin_x
	var max_x: float = maxf(min_x, viewport_size.x - half_size.x - margin_x)
	var min_y: float = half_size.y + margin_top
	var max_y: float = maxf(min_y, viewport_size.y - half_size.y - margin_bottom)
	
	_parent.global_position = Vector2(
		clampf(_parent.global_position.x, min_x, max_x),
		clampf(_parent.global_position.y, min_y, max_y)
	)


func set_half_size(size: Vector2) -> void:
	half_size = Vector2(maxf(0.0, size.x), maxf(0.0, size.y))


func set_margins(x: float, top: float, bottom: float) -> void:
	margin_x = maxf(0.0, x)
	margin_top = maxf(0.0, top)
	margin_bottom = maxf(0.0, bottom)


static func clamp_position(
	position: Vector2,
	viewport_size: Vector2,
	half_size: Vector2,
	margin_x: float = 0.0,
	margin_top: float = 0.0,
	margin_bottom: float = 0.0
) -> Vector2:
	var min_x: float = half_size.x + margin_x
	var max_x: float = maxf(min_x, viewport_size.x - half_size.x - margin_x)
	var min_y: float = half_size.y + margin_top
	var max_y: float = maxf(min_y, viewport_size.y - half_size.y - margin_bottom)
	
	return Vector2(
		clampf(position.x, min_x, max_x),
		clampf(position.y, min_y, max_y)
	)
