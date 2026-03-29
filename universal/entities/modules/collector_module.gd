extends "res://entities/modules/module_base.gd"
class_name CollectorModule

@export var collect_cooldown_sec: float = 5.0
@export var collect_radius_from_ship_edge_cells: float = 5.0
@export var mark_radius_from_ship_edge_cells: float = 7.0
@export var laser_color: Color = Color(0.30, 0.95, 1.0, 1.0)

var _collect_timer: Timer
var _laser_hide_timer: Timer
var _laser: Line2D
var _ship_bounds_provider: Callable
var _is_on_cooldown: bool = false
var _collector_id: int = 0
var _marked_target: WeakRef


func _init() -> void:
	module_id = Constants.MODULE_COLLECTOR
	grid_size = Vector2i.ONE
	metal_cost = Constants.get_module_cost(module_id)
	max_hp = 165
	tap_damage = 28
	sprite_color = Color(1.0, 0.9, 0.2, 1.0) # Желтый
	module_texture = preload("res://assets/sprites/collector.png")


func _ready() -> void:
	_collector_id = get_instance_id()

	_collect_timer = Timer.new()
	_collect_timer.one_shot = true
	_collect_timer.wait_time = collect_cooldown_sec
	_collect_timer.timeout.connect(_on_cooldown_finished)
	add_child(_collect_timer)

	_laser_hide_timer = Timer.new()
	_laser_hide_timer.one_shot = true
	_laser_hide_timer.wait_time = 0.08
	_laser_hide_timer.timeout.connect(_hide_laser)
	add_child(_laser_hide_timer)

	_laser = Line2D.new()
	_laser.width = 3.0
	_laser.default_color = laser_color
	_laser.visible = false
	add_child(_laser)


func _process(_delta: float) -> void:
	if _is_on_cooldown:
		return

	_validate_or_release_mark()

	if _marked_target == null:
		_try_mark_target()
		return

	_try_collect_marked_target()


func _exit_tree() -> void:
	_release_marked_target()


func set_ship_bounds_provider(provider: Callable) -> void:
	_ship_bounds_provider = provider


func _try_mark_target() -> void:
	var target: Node2D = _find_best_debris_target(mark_radius_from_ship_edge_cells, true)
	if target == null:
		return

	if target.has_method("mark_by_collector") and target.mark_by_collector(_collector_id):
		_marked_target = weakref(target)


func _try_collect_marked_target() -> void:
	if _marked_target == null:
		return

	var target_variant: Variant = _marked_target.get_ref()
	if not (target_variant is Node2D):
		_release_marked_target()
		return

	var target: Node2D = target_variant as Node2D
	if not is_instance_valid(target):
		_release_marked_target()
		return

	var ship_rect: Rect2 = _get_ship_bounds_rect()
	if ship_rect.size == Vector2.ZERO:
		_release_marked_target()
		return

	var distance_to_ship_edge: float = _distance_to_rect(target.global_position, ship_rect)
	var mark_radius_px: float = mark_radius_from_ship_edge_cells * cell_size_px
	if distance_to_ship_edge > mark_radius_px:
		_release_marked_target()
		return

	var collect_radius_px: float = collect_radius_from_ship_edge_cells * cell_size_px
	if distance_to_ship_edge > collect_radius_px:
		return

	_show_laser_to(target.global_position)

	var collected: bool = false
	if target.has_method("collect_by_collector"):
		collected = target.collect_by_collector(_collector_id)
	elif target.has_method("collect"):
		target.collect("collector")
		collected = true

	if collected:
		AudioManager.play_collector_gather()
		_marked_target = null
		_start_cooldown()


func _start_cooldown() -> void:
	_is_on_cooldown = true
	_collect_timer.start(collect_cooldown_sec)


func _on_cooldown_finished() -> void:
	_is_on_cooldown = false


func _find_best_debris_target(radius_cells: float, require_markable: bool) -> Node2D:
	var ship_rect: Rect2 = _get_ship_bounds_rect()
	if ship_rect.size == Vector2.ZERO:
		return null

	var debris_nodes: Array = get_tree().get_nodes_in_group("debris")
	var radius_px: float = radius_cells * cell_size_px

	var best_target: Node2D = null
	var best_distance_to_ship_edge: float = INF

	for debris in debris_nodes:
		if not (debris is Node2D):
			continue

		var debris_node: Node2D = debris as Node2D
		if not is_instance_valid(debris_node):
			continue

		var point: Vector2 = debris_node.global_position
		if ship_rect.has_point(point):
			continue

		var distance_to_ship_edge: float = _distance_to_rect(point, ship_rect)
		if distance_to_ship_edge > radius_px:
			continue

		if require_markable:
			if not debris_node.has_method("can_be_marked_by"):
				continue
			if not debris_node.can_be_marked_by(_collector_id):
				continue

		if distance_to_ship_edge < best_distance_to_ship_edge:
			best_distance_to_ship_edge = distance_to_ship_edge
			best_target = debris_node

	return best_target


func _get_ship_bounds_rect() -> Rect2:
	if not _ship_bounds_provider.is_valid():
		return Rect2()

	var ship_rect_variant: Variant = _ship_bounds_provider.call()
	if ship_rect_variant is Rect2:
		return ship_rect_variant as Rect2

	return Rect2()


func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var min_x: float = rect.position.x
	var max_x: float = rect.position.x + rect.size.x
	var min_y: float = rect.position.y
	var max_y: float = rect.position.y + rect.size.y

	var closest: Vector2 = Vector2(
		clamp(point.x, min_x, max_x),
		clamp(point.y, min_y, max_y)
	)

	return point.distance_to(closest)


func _show_laser_to(target_world: Vector2) -> void:
	var local_origin: Vector2 = Vector2(grid_size.x * cell_size_px * 0.5, grid_size.y * cell_size_px * 0.5)
	var local_target: Vector2 = to_local(target_world)

	_laser.points = PackedVector2Array([local_origin, local_target])
	_laser.visible = true
	_laser_hide_timer.start()


func _hide_laser() -> void:
	_laser.visible = false


func _validate_or_release_mark() -> void:
	if _marked_target == null:
		return

	var target_variant: Variant = _marked_target.get_ref()
	if not (target_variant is Node2D):
		_marked_target = null
		return

	var target: Node2D = target_variant as Node2D
	if not is_instance_valid(target):
		_marked_target = null
		return

	if target.has_method("is_marked_by_collector") and not target.is_marked_by_collector(_collector_id):
		_marked_target = null


func _release_marked_target() -> void:
	if _marked_target == null:
		return

	var target_variant: Variant = _marked_target.get_ref()
	if target_variant is Node2D:
		var target: Node2D = target_variant as Node2D
		if is_instance_valid(target) and target.has_method("unmark_by_collector"):
			target.unmark_by_collector(_collector_id)

	_marked_target = null
