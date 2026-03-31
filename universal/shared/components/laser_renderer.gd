extends Node2D
class_name LaserRenderer
## Визуальный компонент лазерного луча.
## Используется турелями и коллекторами для отображения "выстрела" или "сбора".

@export var laser_color: Color = Color(1.0, 0.35, 0.15, 1.0)
@export var laser_width: float = 4.0
@export var flash_duration_sec: float = 0.08

var _line: Line2D
var _hide_timer: Timer


func _ready() -> void:
	_line = Line2D.new()
	_line.width = laser_width
	_line.default_color = laser_color
	_line.visible = false
	add_child(_line)
	
	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.wait_time = flash_duration_sec
	_hide_timer.timeout.connect(_on_hide_timer_timeout)
	add_child(_hide_timer)


func set_color(color: Color) -> void:
	laser_color = color
	if _line != null:
		_line.default_color = color


func set_width(width: float) -> void:
	laser_width = maxf(1.0, width)
	if _line != null:
		_line.width = laser_width


func flash_to_local(origin_local: Vector2, target_local: Vector2) -> void:
	if _line == null:
		return
	
	_line.points = PackedVector2Array([origin_local, target_local])
	_line.visible = true
	_hide_timer.start(flash_duration_sec)


func flash_to_global(origin_global: Vector2, target_global: Vector2) -> void:
	var origin_local: Vector2 = to_local(origin_global)
	var target_local: Vector2 = to_local(target_global)
	flash_to_local(origin_local, target_local)


func flash_from_center_to_global(target_global: Vector2, cell_size_px: float, grid_size: Vector2i) -> void:
	var origin_local: Vector2 = Vector2(grid_size.x * cell_size_px * 0.5, grid_size.y * cell_size_px * 0.5)
	var target_local: Vector2 = to_local(target_global)
	flash_to_local(origin_local, target_local)


func hide_laser() -> void:
	if _line != null:
		_line.visible = false


func is_visible() -> bool:
	return _line != null and _line.visible


func _on_hide_timer_timeout() -> void:
	hide_laser()
