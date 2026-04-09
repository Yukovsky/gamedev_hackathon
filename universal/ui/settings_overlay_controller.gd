extends ColorRect
## Контроллер оверлея настроек.
## Управляет открытием/закрытием и изменением громкости.
## Синхронизирует настройки с AudioManager.

@onready var sound_slider: HSlider = find_child("SoundSlider", true, false)
@onready var music_slider: HSlider = find_child("MusicSlider", true, false)
@onready var btn_back: Button = find_child("BtnBack", true, false)
@onready var btn_main_menu: Button = find_child("BtnMainMenu", true, false)

var _was_paused: bool = false

func _ready() -> void:
	super.hide()
	
	# Подключаем обработчики слайдеров
	if sound_slider:
		sound_slider.value_changed.connect(_on_sound_slider_changed)
		sound_slider.value = AudioManager.get_sfx_volume()
	
	if music_slider:
		music_slider.value_changed.connect(_on_music_slider_changed)
		music_slider.value = AudioManager.get_music_volume()
	
	# Подключаем кнопки
	if btn_back:
		btn_back.pressed.connect(_on_btn_back_pressed)
	
	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_btn_main_menu_pressed)
	
	# Подключаемся к сигналам открытия/закрытия
	if GameEvents.has_signal("settings_overlay_open"):
		GameEvents.settings_overlay_open.connect(open_settings)
	if GameEvents.has_signal("settings_overlay_close"):
		GameEvents.settings_overlay_close.connect(close_settings)

func _on_sound_slider_changed(value: float) -> void:
	"""Изменяет громкость звуков."""
	AudioManager.set_sfx_volume(value)

func _on_music_slider_changed(value: float) -> void:
	"""Изменяет громкость музыки."""
	AudioManager.set_music_volume(value)

func _on_btn_back_pressed() -> void:
	"""Закрывает оверлей настроек."""
	AudioManager.play_ui_close()
	if _was_paused:
		get_tree().paused = false
	close_settings()

func _on_btn_main_menu_pressed() -> void:
	"""Переходит в главное меню."""
	AudioManager.play_ui_close()
	if _was_paused:
		get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/start_menu.tscn")

func toggle_visibility() -> void:
	"""Переключает видимость оверлея."""
	if visible:
		close_settings()
	else:
		open_settings()

func open_settings() -> void:
	"""Показывает оверлей и ставит игру на паузу."""
	_was_paused = get_tree().paused
	get_tree().paused = true
	# Синхронизируем значения слайдеров с AudioManager
	if sound_slider:
		sound_slider.value = AudioManager.get_sfx_volume()
	if music_slider:
		music_slider.value = AudioManager.get_music_volume()
	super.show()

func close_settings() -> void:
	"""Скрывает оверлей."""
	super.hide()
