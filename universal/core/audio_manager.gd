extends Node

const AudioCatalogScript: Script = preload("res://core/audio_catalog.gd")

const SETTINGS_PATH: String = "user://audio_settings.cfg"
const SETTINGS_SECTION: String = "audio"
const SETTINGS_KEY_MUSIC_VOLUME: String = "music_volume"
const SETTINGS_KEY_SFX_VOLUME: String = "sfx_volume"

const SILENT_DB: float = -80.0
const DEFAULT_MUSIC_VOLUME: float = 1.0
const DEFAULT_SFX_VOLUME: float = 1.0

var _bgm_player: AudioStreamPlayer
var _engine_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player: int = 0
var _last_module_hit_time_ms: int = -10000
var _last_raider_hit_time_ms: int = -10000
var _bgm_enabled: bool = true
var _stream_cache: Dictionary = {}
var _music_volume_linear: float = DEFAULT_MUSIC_VOLUME
var _sfx_volume_linear: float = DEFAULT_SFX_VOLUME


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_audio_settings()
	_setup_players()
	_warmup_stream_cache()
	_connect_events()
	_play_bgm()
	_update_engine_playback()


func _setup_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = _resolve_volume_db(AudioCatalogScript.TAG_MUSIC_BGM_MAIN)
	_bgm_player.autoplay = false
	add_child(_bgm_player)

	_engine_player = AudioStreamPlayer.new()
	_engine_player.bus = "Master"
	_engine_player.volume_db = _resolve_volume_db(AudioCatalogScript.TAG_MUSIC_ENGINE_LOOP)
	_engine_player.autoplay = false
	add_child(_engine_player)

	for _i in range(12):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = _resolve_volume_db(AudioCatalogScript.TAG_UI_OPEN)
		add_child(p)
		_sfx_players.append(p)


func get_music_volume() -> float:
	return _music_volume_linear


func get_sfx_volume() -> float:
	return _sfx_volume_linear


func set_music_volume(value: float) -> void:
	_music_volume_linear = clampf(value, 0.0, 1.0)
	_apply_music_levels()
	_save_audio_settings()


func set_sfx_volume(value: float) -> void:
	_sfx_volume_linear = clampf(value, 0.0, 1.0)
	_apply_active_sfx_levels()
	_save_audio_settings()

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
	GameEvents.raider_damaged.connect(_on_raider_damaged)
	GameEvents.raider_bite.connect(_on_raider_bite)
	GameEvents.raider_destroyed.connect(_on_raider_destroyed)
	GameEvents.game_finished.connect(_on_game_finished)


func _warmup_stream_cache() -> void:
	# Прогрев коротких частых SFX, чтобы первый клик звучал без задержки.
	_load_audio_stream(AudioCatalogScript.TAG_GAMEPLAY_COIN)
	_load_audio_stream(AudioCatalogScript.TAG_GAMEPLAY_COLLECTOR_GATHER)
	_load_audio_stream(AudioCatalogScript.TAG_COMBAT_RAIDER_DAMAGE)
	_load_audio_stream(AudioCatalogScript.TAG_COMBAT_RAIDER_DESTROY)


func _process(_delta: float) -> void:
	_update_engine_playback()


func _update_engine_playback() -> void:
	if _engine_player == null:
		return

	if get_tree().paused:
		if _engine_player.playing:
			_engine_player.stop()
		return

	if _engine_player.stream == null:
		var engine_stream: AudioStream = _load_audio_stream(AudioCatalogScript.TAG_MUSIC_ENGINE_LOOP)
		if engine_stream == null:
			return
		_engine_player.stream = engine_stream

	_engine_player.volume_db = _resolve_volume_db(AudioCatalogScript.TAG_MUSIC_ENGINE_LOOP)
	if not _engine_player.playing:
		_engine_player.play()


func _play_bgm() -> void:
	if not _bgm_enabled:
		return

	if _bgm_player == null:
		return

	var stream: AudioStream = _load_audio_stream(AudioCatalogScript.TAG_MUSIC_BGM_MAIN)
	if stream == null:
		return

	_bgm_player.stream = stream
	_bgm_player.volume_db = _resolve_volume_db(AudioCatalogScript.TAG_MUSIC_BGM_MAIN)
	if not _bgm_player.playing:
		_bgm_player.play()


func play_ui_open() -> void:
	_play_sfx(AudioCatalogScript.TAG_UI_OPEN)


func play_collector_gather() -> void:
	_play_sfx(AudioCatalogScript.TAG_GAMEPLAY_COLLECTOR_GATHER)


func play_turret_shot() -> void:
	_play_sfx(AudioCatalogScript.TAG_GAMEPLAY_TURRET_SHOT)


func _on_garbage_clicked(_amount: int) -> void:
	_play_sfx(AudioCatalogScript.TAG_GAMEPLAY_COIN)


func _on_module_built(_module_type: String, _position: Vector2) -> void:
	_play_sfx(AudioCatalogScript.TAG_GAMEPLAY_BUILD_PLACE)

func _on_module_repaired() -> void:
	_play_sfx(AudioCatalogScript.TAG_GAMEPLAY_BUILD_PLACE)

func _on_module_damaged(_module_type: String, _current_hp: int, _max_hp: int, _position: Vector2, _source: String) -> void:
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_module_hit_time_ms < 70:
		return
	_last_module_hit_time_ms = now_ms
	_play_sfx(AudioCatalogScript.TAG_COMBAT_MODULE_HIT)


func _on_module_destroyed(_module_type: String, _position: Vector2) -> void:
	_play_sfx(AudioCatalogScript.TAG_COMBAT_MODULE_DESTROY)


func _on_raider_bite(_position: Vector2) -> void:
	_play_sfx(AudioCatalogScript.TAG_COMBAT_RAIDER_BITE)


func _on_raider_damaged(_current_hp: int, _max_hp: int, _position: Vector2) -> void:
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_raider_hit_time_ms < 60:
		return
	_last_raider_hit_time_ms = now_ms
	_play_sfx(AudioCatalogScript.TAG_COMBAT_RAIDER_DAMAGE)


func _on_raider_destroyed(_position: Vector2, _evolution_level: int, _source: String) -> void:
	_play_sfx(AudioCatalogScript.TAG_COMBAT_RAIDER_DESTROY)


func _on_game_finished(outcome: String, _reason: String) -> void:
	if outcome == "win":
		_play_sfx(AudioCatalogScript.TAG_SYSTEM_WIN)
	else:
		_play_sfx(AudioCatalogScript.TAG_SYSTEM_LOSE)


func _play_sfx(tag: String, base_volume_db: float = INF) -> void:
	if _sfx_players.is_empty():
		return

	if not AudioCatalogScript.has_tag(tag):
		return

	var stream: AudioStream = _load_audio_stream(tag)
	if stream == null:
		return

	var resolved_base_db: float = AudioCatalogScript.get_base_db(tag)
	if is_finite(base_volume_db):
		resolved_base_db = base_volume_db

	var player: AudioStreamPlayer = _sfx_players[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
	player.stop()
	player.stream = stream
	player.set_meta("audio_tag", tag)
	player.set_meta("base_volume_db", resolved_base_db)
	player.volume_db = resolved_base_db + _get_gain_db_for_class(AudioCatalogScript.get_audio_class(tag))
	player.play()


func _load_audio_stream(tag: String) -> AudioStream:
	if not AudioCatalogScript.has_tag(tag):
		return null

	var path: String = AudioCatalogScript.get_stream_path(tag)
	var loop: bool = AudioCatalogScript.is_looped(tag)
	return _load_audio_stream_from_path(path, loop)


func _load_audio_stream_from_path(path: String, loop: bool) -> AudioStream:
	if _stream_cache.has(path):
		var cached: AudioStream = _stream_cache[path] as AudioStream
		if cached != null:
			if loop and cached is AudioStreamMP3:
				var cached_looped := (cached as AudioStreamMP3).duplicate() as AudioStreamMP3
				cached_looped.loop = true
				return cached_looped
			return cached

	var stream: AudioStream = ResourceLoader.load(path) as AudioStream
	if stream != null:
		_stream_cache[path] = stream
		if loop and stream is AudioStreamMP3:
			var looped := (stream as AudioStreamMP3).duplicate() as AudioStreamMP3
			looped.loop = true
			return looped
		return stream

	if not path.to_lower().ends_with(".mp3"):
		return null

	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var bytes := file.get_buffer(file.get_length())
	file.close()
	if bytes.is_empty():
		return null

	var mp3_stream := AudioStreamMP3.new()
	mp3_stream.data = bytes
	mp3_stream.loop = loop
	if not loop:
		_stream_cache[path] = mp3_stream
	return mp3_stream


func _apply_music_levels() -> void:
	if _bgm_player != null:
		_bgm_player.volume_db = _resolve_volume_db(AudioCatalogScript.TAG_MUSIC_BGM_MAIN)
	if _engine_player != null:
		_engine_player.volume_db = _resolve_volume_db(AudioCatalogScript.TAG_MUSIC_ENGINE_LOOP)


func _apply_active_sfx_levels() -> void:
	for player_any in _sfx_players:
		if player_any == null:
			continue
		var player: AudioStreamPlayer = player_any as AudioStreamPlayer
		if player == null:
			continue
		if not player.has_meta("audio_tag"):
			continue
		var tag: String = str(player.get_meta("audio_tag", ""))
		if tag.is_empty() or not AudioCatalogScript.has_tag(tag):
			continue
		var base_volume_db: float = float(player.get_meta("base_volume_db", AudioCatalogScript.get_base_db(tag)))
		player.volume_db = base_volume_db + _get_gain_db_for_class(AudioCatalogScript.get_audio_class(tag))


func _resolve_volume_db(tag: String) -> float:
	if not AudioCatalogScript.has_tag(tag):
		return SILENT_DB
	var base_db: float = AudioCatalogScript.get_base_db(tag)
	var audio_class: AudioCatalogScript.AudioClass = AudioCatalogScript.get_audio_class(tag)
	return base_db + _get_gain_db_for_class(audio_class)


func _get_gain_db_for_class(audio_class: AudioCatalogScript.AudioClass) -> float:
	if audio_class == AudioCatalogScript.AudioClass.MUSIC:
		return _linear_to_db(_music_volume_linear)
	return _linear_to_db(_sfx_volume_linear)


func _linear_to_db(value: float) -> float:
	if value <= 0.0001:
		return SILENT_DB
	return linear_to_db(value)


func _load_audio_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: int = config.load(SETTINGS_PATH)
	if err != OK:
		_music_volume_linear = DEFAULT_MUSIC_VOLUME
		_sfx_volume_linear = DEFAULT_SFX_VOLUME
		return

	_music_volume_linear = clampf(float(config.get_value(SETTINGS_SECTION, SETTINGS_KEY_MUSIC_VOLUME, DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	_sfx_volume_linear = clampf(float(config.get_value(SETTINGS_SECTION, SETTINGS_KEY_SFX_VOLUME, DEFAULT_SFX_VOLUME)), 0.0, 1.0)


func _save_audio_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var _err: int = config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY_MUSIC_VOLUME, _music_volume_linear)
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY_SFX_VOLUME, _sfx_volume_linear)
	config.save(SETTINGS_PATH)
