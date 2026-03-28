extends Node2D

@export var speed: float = 150.0
@export var loot_range: float = 20.0
@export var loot_time: float = 3.0

var target_module: Node2D = null
var _is_looting: bool = false
var _loot_timer: float = 0.0
var _is_defeated: bool = false

@onready var _sprite: ColorRect = $Sprite
@onready var _clickable: Area2D = $ClickableComponent

func _ready() -> void:
	add_to_group("raiders")
	if _clickable:
		_clickable.input_event.connect(_on_input_event)
	
	# Поиск центра корабля как начальной цели
	_update_target()

func _process(delta: float) -> void:
	if _is_defeated: return
	
	if _is_looting:
		_process_looting(delta)
	else:
		_move_towards_target(delta)

func _update_target() -> void:
	# Ищем ближайший модуль в группе "modules" или просто летим к центру корабля
	var modules = get_tree().get_nodes_in_group("modules")
	if modules.size() > 0:
		var closest = modules[0]
		var min_dist = global_position.distance_to(closest.global_position)
		for m in modules:
			var d = global_position.distance_to(m.global_position)
			if d < min_dist:
				min_dist = d
				closest = m
		target_module = closest
	else:
		target_module = null

func _move_towards_target(delta: float) -> void:
	var target_pos = Vector2(540, 1200) # Центр экрана по умолчанию
	if is_instance_valid(target_module):
		target_pos = target_module.global_position
	
	var dir = (target_pos - global_position).normalized()
	global_position += dir * speed * delta
	
	if global_position.distance_to(target_pos) < loot_range:
		_start_looting()

func _process_looting(delta: float) -> void:
	_loot_timer += delta
	# Визуальный эффект мародерства (мигание)
	modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01)
	
	if _loot_timer >= loot_time:
		_finish_looting()

func _start_looting() -> void:
	_is_looting = true
	_loot_timer = 0.0
	print("Raider started looting!")

func _finish_looting() -> void:
	if is_instance_valid(target_module) and target_module.has_method("queue_free"):
		# Проверяем, не является ли модуль Ядром
		if target_module.get("module_id") == Constants.MODULE_CORE:
			print("Raider: Core is too strong to loot!")
		else:
			print("Raider looted a module: ", target_module.get("module_id"))
			target_module.queue_free()
	queue_free()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		defeat()
	elif event is InputEventScreenTouch and event.pressed:
		defeat()

func defeat() -> void:
	if _is_defeated: return
	_is_defeated = true
	print("Raider defeated!")
	GameEvents.raider_defeated.emit(self)
	# Звук клика через SoundManager
	if SoundManager: SoundManager.play_button_click()
	queue_free()
