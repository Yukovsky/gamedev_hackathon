extends Node

const BGM_PATH: String = "res://assets/audio/music/Glass_Orbiting.mp3"

const SFX_UI_CLICK: String = "res://assets/audio/game_sfx/ui_click.wav"
const SFX_UI_OPEN: String = "res://assets/audio/game_sfx/ui_open.wav"
const SFX_UI_ERROR: String = "res://assets/audio/game_sfx/ui_error.wav"
const SFX_BUILD_PLACE: String = "res://assets/audio/dima_sfx/build_place_dima.wav"
const SFX_COIN: String = "res://assets/audio/game_sfx/coin.wav"
const SFX_MODULE_HIT: String = "res://assets/audio/game_sfx/module_hit.wav"
const SFX_MODULE_DESTROY: String = "res://assets/audio/game_sfx/module_destroy.wav"
# const SFX_RAIDER_SPAWN: String = "res://assets/audio/game_sfx/raider_spawn.wav"
const SFX_RAIDER_BITE: String = "res://assets/audio/dima_sfx/raider_bite_dima.wav"
const SFX_RAIDER_DESTROY: String = "res://assets/audio/dima_sfx/enemy_death_dima.wav"
const SFX_TURRET_SHOT: String = "res://assets/audio/game_sfx/turret_shot.mp3"
const SFX_WIN: String = "res://assets/audio/game_sfx/win.wav"
const SFX_LOSE: String = "res://assets/audio/game_sfx/lose.wav"

@export var bgm_volume_db: float = -18.0 # тише фоновой музыки
@export var sfx_volume_db: float = -8.0

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player: int = 0
var _last_module_hit_time_ms: int = -10000
var _bgm_enabled: bool = true


func _ready() -> void:
	_setup_players()
	_connect_events()
	_play_bgm()


func _setup_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = bgm_volume_db
	_bgm_player.autoplay = false
	add_child(_bgm_player)

	for _i in range(12):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = sfx_volume_db
		add_child(p)
		_sfx_players.append(p)

func is_bgm_enabled() -> bool:
	return _bgm_enabled

func set_bgm_enabled(enabled: bool) -> void:
	_bgm_enabled = enabled
	if _bgm_enabled:
		_play_bgm()
	else:
		if _bgm_player != null:
			_bgm_player.stop()

func toggle_bgm() -> bool:
	set_bgm_enabled(not _bgm_enabled)
	return _bgm_enabled


func _connect_events() -> void:
	GameEvents.garbage_clicked.connect(_on_garbage_clicked)
	GameEvents.module_built.connect(_on_module_built)
	GameEvents.module_damaged.connect(_on_module_damaged)
	GameEvents.module_destroyed.connect(_on_module_destroyed)
	#GameEvents.raider_spawned.connect(_on_raider_spawned)
	GameEvents.raider_bite.connect(_on_raider_bite)
	GameEvents.raider_destroyed.connect(_on_raider_destroyed)
	GameEvents.game_finished.connect(_on_game_finished)


func _play_bgm() -> void:
	if not _bgm_enabled:
		return

	if _bgm_player == null:
		return

	# Попытка прямой загрузки ресурса (лучше для Android)
	var stream := ResourceLoader.load(BGM_PATH) as AudioStream
	if stream == null:
		# Фоллбек на исходный MP3 через прямое чтение файла, если путь есть и поддерживается
		if not FileAccess.file_exists(BGM_PATH):
			return
		var file := FileAccess.open(BGM_PATH, FileAccess.READ)
		if file == null:
			return
		var bytes := file.get_buffer(file.get_length())
		file.close()
		if bytes.is_empty():
			return
		var mp3_stream := AudioStreamMP3.new()
		mp3_stream.data = bytes
		mp3_stream.loop = true
		stream = mp3_stream

	_bgm_player.stream = stream
	_bgm_player.volume_db = bgm_volume_db
	if not _bgm_player.playing:
		_bgm_player.play()


func play_ui_click() -> void:
	_play_sfx(SFX_UI_CLICK,-1000)


func play_ui_open() -> void:
	_play_sfx(SFX_UI_OPEN)


func play_ui_error() -> void:
	_play_sfx(SFX_UI_ERROR)


func play_turret_shot() -> void:
	_play_sfx(SFX_TURRET_SHOT, -10.0)


func _on_garbage_clicked(_amount: int) -> void:
	_play_sfx(SFX_COIN, -20.0)


func _on_module_built(_module_type: String, _position: Vector2) -> void:
	_play_sfx(SFX_BUILD_PLACE)


func _on_module_damaged(_module_type: String, _current_hp: int, _max_hp: int, _position: Vector2, _source: String) -> void:
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_module_hit_time_ms < 70:
		return
	_last_module_hit_time_ms = now_ms
	_play_sfx(SFX_MODULE_HIT, -10.0)


func _on_module_destroyed(_module_type: String, _position: Vector2) -> void:
	_play_sfx(SFX_MODULE_DESTROY)


#func _on_raider_spawned(_position: Vector2) -> void:
	#_play_sfx(SFX_RAIDER_SPAWN, -10.0)


func _on_raider_bite(_position: Vector2) -> void:
	_play_sfx(SFX_RAIDER_BITE, -9.0)


func _on_raider_destroyed(_position: Vector2, _evolution_level: int, _source: String) -> void:
	_play_sfx(SFX_RAIDER_DESTROY)


func _on_game_finished(outcome: String, _reason: String) -> void:
	if outcome == "win":
		_play_sfx(SFX_WIN)
	else:
		_play_sfx(SFX_LOSE)


func _play_sfx(path: String, volume: float = -8.0) -> void:
	if _sfx_players.is_empty():
		return

	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return

	var player: AudioStreamPlayer = _sfx_players[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
	player.stop()
	player.stream = stream
	player.volume_db = volume
	player.play()
