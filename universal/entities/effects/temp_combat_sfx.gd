extends Node2D
class_name TempCombatSfx

@export var mix_rate: int = 44100
@export var amplitude: float = 0.24


func play_spawn(position_world: Vector2) -> void:
	_play_tone(position_world, 10.0, 0.08, -50.0)


func play_bite(position_world: Vector2) -> void:
	_play_tone(position_world, 190.0, 0.12, -10.0)


func play_destroy(position_world: Vector2) -> void:
	_play_tone(position_world, 120.0, 0.2, -7.0)


func _play_tone(position_world: Vector2, frequency: float, duration: float, volume_db: float) -> void:
	var player := AudioStreamPlayer2D.new()
	player.global_position = position_world
	player.volume_db = volume_db

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = mix_rate
	generator.buffer_length = max(0.12, duration + 0.08)
	player.stream = generator

	add_child(player)
	player.play()

	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		player.queue_free()
		return

	var total_samples: int = int(float(mix_rate) * duration)
	for i in range(total_samples):
		var t: float = float(i) / float(mix_rate)
		var env: float = 1.0 - (t / max(0.001, duration))
		var sample: float = sin(TAU * frequency * t) * amplitude * env
		playback.push_frame(Vector2(sample, sample))

	var cleanup_timer := Timer.new()
	cleanup_timer.one_shot = true
	cleanup_timer.wait_time = duration + 0.15
	cleanup_timer.timeout.connect(player.queue_free)
	cleanup_timer.timeout.connect(cleanup_timer.queue_free)
	add_child(cleanup_timer)
	cleanup_timer.start()
