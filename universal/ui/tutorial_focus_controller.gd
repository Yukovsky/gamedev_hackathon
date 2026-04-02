extends RefCounted
class_name TutorialFocusController

const TUTORIAL_FOCUS_PULSE: Color = Color(6.5, 6.5, 6.5, 1.0)
const TUTORIAL_FOCUS_BASE_BOOST: float = 2.2

var _tutorial_target_controls: Dictionary = {}
var _tutorial_focused_item: CanvasItem
var _tutorial_focus_tween: Tween


func register_targets(targets: Dictionary) -> void:
	_tutorial_target_controls = targets


func register_target(target_id: String, target: CanvasItem) -> void:
	if target_id.is_empty() or target == null:
		return
	_tutorial_target_controls[target_id] = target


func unregister_target(target_id: String) -> void:
	if target_id.is_empty():
		return
	if _tutorial_target_controls.has(target_id):
		_tutorial_target_controls.erase(target_id)
	if get_focused_target_id() == target_id:
		clear_focus()


func has_target(target_id: String) -> bool:
	if target_id.is_empty():
		return false
	return _tutorial_target_controls.has(target_id)


func is_target_valid(target_id: String) -> bool:
	if target_id.is_empty() or not _tutorial_target_controls.has(target_id):
		return false
	var target: Variant = _tutorial_target_controls[target_id]
	if not (target is CanvasItem):
		return false
	return is_instance_valid(target)


func clear_focus() -> void:
	if _tutorial_focus_tween:
		_tutorial_focus_tween.kill()
		_tutorial_focus_tween = null
	if _tutorial_focused_item and is_instance_valid(_tutorial_focused_item):
		_tutorial_focused_item.modulate = Color.WHITE
	_tutorial_focused_item = null


func process_focus_tracking() -> void:
	if _tutorial_focused_item == null:
		return
	if not is_instance_valid(_tutorial_focused_item):
		return
	if not _is_target_visible(_tutorial_focused_item):
		return
	var target_rect: Rect2 = _resolve_target_rect(_tutorial_focused_item)
	if target_rect.size.x > 0.0 and target_rect.size.y > 0.0:
		GameEvents.tutorial_target_rect_changed.emit(get_focused_target_id(), target_rect)


func focus_target(target_id: String, accent_color: Color) -> void:
	clear_focus()
	if not _tutorial_target_controls.has(target_id):
		return

	var target: Variant = _tutorial_target_controls[target_id]
	if not (target is CanvasItem):
		return
	if not is_instance_valid(target):
		return

	_tutorial_focused_item = target as CanvasItem
	if not _is_target_visible(_tutorial_focused_item):
		return

	var boosted_focus_color: Color = Color(
		accent_color.r * TUTORIAL_FOCUS_BASE_BOOST,
		accent_color.g * TUTORIAL_FOCUS_BASE_BOOST,
		accent_color.b * TUTORIAL_FOCUS_BASE_BOOST,
		1.0
	)

	_tutorial_focused_item.modulate = boosted_focus_color
	_tutorial_focus_tween = _tutorial_focused_item.create_tween()
	_tutorial_focus_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tutorial_focus_tween.set_loops()
	_tutorial_focus_tween.set_trans(Tween.TRANS_SINE)
	_tutorial_focus_tween.set_ease(Tween.EASE_IN_OUT)
	_tutorial_focus_tween.tween_property(_tutorial_focused_item, "modulate", TUTORIAL_FOCUS_PULSE, 0.3)
	_tutorial_focus_tween.tween_property(_tutorial_focused_item, "modulate", boosted_focus_color, 0.3)

	var target_rect: Rect2 = _resolve_target_rect(_tutorial_focused_item)
	if target_rect.size.x > 0.0 and target_rect.size.y > 0.0:
		GameEvents.tutorial_target_rect_changed.emit(target_id, target_rect)


func get_focused_target_id() -> String:
	for id in _tutorial_target_controls.keys():
		if _tutorial_target_controls[id] == _tutorial_focused_item:
			return str(id)
	return ""


func _is_target_visible(target: CanvasItem) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target is Control:
		return (target as Control).visible
	if target is Node2D:
		return (target as Node2D).visible
	if target is CanvasItem:
		return (target as CanvasItem).visible
	return false


func _resolve_target_rect(target: CanvasItem) -> Rect2:
	if target == null or not is_instance_valid(target):
		return Rect2()

	if target is Control:
		return (target as Control).get_global_rect()

	if target is Sprite2D:
		var sprite: Sprite2D = target as Sprite2D
		if sprite.texture == null:
			return Rect2(sprite.global_position, Vector2.ZERO)
		var texture_size: Vector2 = sprite.texture.get_size()
		var scaled_size: Vector2 = texture_size * sprite.global_scale.abs()
		var top_left: Vector2 = sprite.global_position
		if sprite.centered:
			top_left -= scaled_size * 0.5
		return Rect2(top_left, scaled_size)

	if target is Node2D:
		var node_2d: Node2D = target as Node2D
		return Rect2(node_2d.global_position - Vector2(8.0, 8.0), Vector2(16.0, 16.0))

	return Rect2()
