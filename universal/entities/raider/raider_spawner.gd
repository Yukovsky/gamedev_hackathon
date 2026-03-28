extends Node2D

@export var spawn_interval: float = 15.0
@export var raider_scene: PackedScene = preload("res://entities/raider/raider.tscn")

var _spawn_timer: Timer

func _ready() -> void:
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.autostart = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	
	# Первый спавн через небольшую задержку
	await get_tree().create_timer(5.0).timeout
	_spawn_raider()

func _on_spawn_timer_timeout() -> void:
	_spawn_raider()

func _spawn_raider() -> void:
	if not raider_scene: return
	
	var raider = raider_scene.instantiate()
	var viewport_size = get_viewport_rect().size
	
	# Спавним по краям экрана
	var edge = randi() % 4
	var spawn_pos = Vector2.ZERO
	
	match edge:
		0: # Сверху
			spawn_pos = Vector2(randf_range(0, viewport_size.x), -50)
		1: # Снизу
			spawn_pos = Vector2(randf_range(0, viewport_size.x), viewport_size.y + 50)
		2: # Слева
			spawn_pos = Vector2(-50, randf_range(0, viewport_size.y))
		3: # Справа
			spawn_pos = Vector2(viewport_size.x + 50, randf_range(0, viewport_size.y))
	
	raider.global_position = spawn_pos
	get_parent().add_child(raider) # Добавляем в Main, а не в спавнер
	GameEvents.raider_spawned.emit(raider)
	print("Raider spawned at ", spawn_pos)
