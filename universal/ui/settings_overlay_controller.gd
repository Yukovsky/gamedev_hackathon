extends ColorRect
## Контроллер оверлея настроек.
## Управляет открытием/закрытием и изменением громкости.

@onready var sound_slider: HSlider = find_child("SoundSlider", true, false)
@onready var music_slider: HSlider = find_child("MusicSlider", true, false)
@onready var btn_back: Button = find_child("BtnBack", true, false)
@onready var btn_main_menu: Button = find_child("BtnMainMenu", true, false)

var _audio_bus_sfx: int = -1
var _audio_bus_music: int = -1

func _ready() -> void:
	hide()
	
	# Находим индексы audio bus'ов
	_audio_bus_sfx = AudioServer.get_bus_index("SFX") if AudioServer.get_bus_index("SFX") != -1 else 0
	_audio_bus_music = AudioServer.get_bus_index("Music") if AudioServer.get_bus_index("Music") != -1 else 1
	
	# Подключаем обработчики слайдеров
	if sound_slider:
		sound_slider.value_changed.connect(_on_sound_slider_changed)
		sound_slider.value = db_to_linear(AudioServer.get_bus_volume_db(_audio_bus_sfx))
	
	if music_slider:
		music_slider.value_changed.connect(_on_music_slider_changed)
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(_audio_bus_music))
	
	# Подключаем кнопки
	if btn_back:
		btn_back.pressed.connect(_on_btn_back_pressed)
	
	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_btn_main_menu_pressed)
	
	# Подключаемся к сигналам открытия/закрытия
	if GameEvents.has_signal("settings_overlay_open"):
		GameEvents.settings_overlay_open.connect(show)
	if GameEvents.has_signal("settings_overlay_close"):
		GameEvents.settings_overlay_close.connect(hide)

func _on_sound_slider_changed(value: float) -> void:
	"""Изменяет громкость звуков."""
	AudioServer.set_bus_volume_db(_audio_bus_sfx, linear_to_db(value))

func _on_music_slider_changed(value: float) -> void:
	"""Изменяет громкость музыки."""
	AudioServer.set_bus_volume_db(_audio_bus_music, linear_to_db(value))

func _on_btn_back_pressed() -> void:
	"""Закрывает оверлей настроек."""
	if AudioManager:
		AudioManager.play_ui_close()
	hide()

func _on_btn_main_menu_pressed() -> void:
	"""Переходит в главное меню."""
	if AudioManager:
		AudioManager.play_ui_close()
	get_tree().change_scene_to_file("res://ui/start_menu.tscn")

func toggle_visibility() -> void:
	"""Переключает видимость оверлея."""
	if visible:
		hide()
	else:
		show()
