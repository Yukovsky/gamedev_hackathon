extends Node
## Глобальный менеджер звука (Autoload: SoundManager)

var sound_click: AudioStream
var sound_build: AudioStream
var sound_garbage: AudioStream

func _ready() -> void:
	# Используем load вместо preload для безопасности
	sound_click = load("res://assets/sounds/click.wav")
	sound_build = load("res://assets/sounds/build.wav")
	sound_garbage = load("res://assets/sounds/garbage.wav")
	
	GameEvents.garbage_clicked.connect(_on_garbage_clicked)
	GameEvents.module_built.connect(_on_module_built)
	GameEvents.game_started.connect(_on_game_started)
	
	print("SoundManager Initialized (Safe Mode)")

func play_sfx(stream: AudioStream, pitch_variation: float = 0.1) -> void:
	if stream == null:
		return
		
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _on_garbage_clicked(_amount: int) -> void:
	play_sfx(sound_garbage, 0.2)

func _on_module_built(_type: String, _pos: Vector2) -> void:
	play_sfx(sound_build, 0.05)

func _on_game_started() -> void:
	play_sfx(sound_click)

func play_button_click() -> void:
	play_sfx(sound_click, 0.1)
