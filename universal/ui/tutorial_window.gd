extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var dialog_panel: PanelContainer = $Overlay/MarginContainer/HBoxContainer/DialogPanel
@onready var dialog_text: RichTextLabel = $Overlay/MarginContainer/HBoxContainer/DialogPanel/MarginContainer/VBoxContainer/DialogText
@onready var name_label: Label = $Overlay/MarginContainer/HBoxContainer/DialogPanel/MarginContainer/VBoxContainer/NameLabel

const BASE_DIALOG_PANEL_HEIGHT: float = 224.0
const DIALOG_CONTENT_PADDING: float = 110.0
const MAX_DIALOG_HEIGHT_RATIO: float = 0.55
const TYPEWRITER_CHAR_DELAY: float = 0.03
const TEXT_DESCENDER_PADDING: float = 10.0
const TUTORIAL_ID_NADYA_ONE_TIME: String = "nadya_first_launch_done"

enum TutorialMode {
	FULL,
	MAX_METAL_TRAINING,
	FULL_CYCLE_TRAINING,
}

@export var tutorial_mode: TutorialMode = TutorialMode.FULL
@export var ignore_save_flags: bool = false

const COLOR_HULL_TEXT: String = "#4DCC4D"
const COLOR_REACTOR_TEXT: String = "#F2BD33"
const COLOR_COLLECTOR_TEXT: String = "#FFE633"
const COLOR_TURRET_TEXT: String = "#F2522E"
const COLOR_CORE_TEXT: String = "#F0D020"

# ========== ТЕКСТЫ ДИАЛОГОВ ==========
var intro_steps: Array[String] = [
	"Капитан, вы меня слышите? Это [color=yellow]Н.А.Д.Я.[/color], ваша Наблюдательная Автономная Диспетчерская Ячейка.",
	"Наш корабль серьезно пострадал. Мы застряли в секторе космического мусора.",
]

var gathering_steps: Array[String] = [
	"Чтобы выжить, нам нужно собирать обломки. Нажимайте по пролетающему [color=brown]МУСОРУ[/color], чтобы добыть [color=orange]МЕТАЛЛ[/color]!",
]

var raider_warning_steps: Array[String] = [
	"Капитан, тревога! Это [color=red]ВРАГ[/color]. Он хочет забрать наши ресурсы.",
    "Чтобы уничтожить врага, нажимайте по нему так быстро как только сможете"
]

var raider_defense_steps: Array[String] = [
	"Отличная работа, Капитан!",
	"Напоминаю, для автоматизации защиты от [color=red]ВРАГОВ[/color] постройте ТУРЕЛИ: их можно купить в ЦЕХЕ."
]

var shop_invite_steps: Array[String] = [
	"Капитан, у вас достаточно [color=orange]МЕТАЛЛА[/color]! Зайдите в [color=green]ЦЕХ[/color], чтобы купить модули для корабля."
]

var shop_guide_steps: Array[String] = [
	"ЦЕХ открыт! Я расскажу об основных модулях, каждый  из них уникален и необходим нашему кораблю:",
	"[color=%s]КОРПУС[/color] — увеличивает максимальное количество ресурсов." % COLOR_HULL_TEXT,
	"[color=%s]РЕАКТОР[/color] — без них у нас не будет энергии для работы модулей." % COLOR_REACTOR_TEXT,
	"Реактор запитывает соседние ячейки и позволяет строить модули в них",
	"Обратите внимание, что [color=%s]РЕАКТОРЫ[/color] не должны питать [color=%s]ЯДРО[/color] и наоборот" % [COLOR_REACTOR_TEXT, COLOR_CORE_TEXT],
	"[color=%s]СБОРЩИК[/color] — автоматически добывает ближайший к вашему кораблю мусор" % COLOR_COLLECTOR_TEXT,
	"[color=%s]ТУРЕЛЬ[/color] — оборонительный модуль, атакует врагов автоматически." % COLOR_TURRET_TEXT,
	"[color=%s]ЯДРО[/color] — увеличивает количество металла, получаемого с каждого обломка." % COLOR_CORE_TEXT,
	"Сейчас у нас хватает [color=orange]МЕТАЛЛА[/color] на [color=%s]КОРПУС[/color]. Самое время его приобрести" % COLOR_HULL_TEXT,
	"Не переживайте, я буду указывать на разрешенные места для строительства модулей",
]

var reactor_guide_steps: Array[String] = [
	"Капитан, вы накопили [color=orange]375 МЕТАЛЛА[/color]! Этого хватит для постройки [color=cyan]РЕАКТОРА[/color].",
	"Каждому новому отсеку нужна энергия. Постройте [color=cyan]РЕАКТОР[/color], чтобы увеличить энергоемкость корабля и продолжить расширение базы!",
    "Если вам удастся построить [color=cyan]4 РЕАКТОРА[/color],нам хватит энергии для [color=cyan]ГИПЕРПРЫЖКA[/color]"
]

var max_resources_steps: Array[String] = [
	"Капитан! Мы накопили максимальное количество [color=orange]МЕТАЛЛА[/color]!",
	"Нам нужно потратить ресурсы на постройку модулей или апгрейдов. Направляйтесь в [color=cyan]ЦЕХ[/color] и используйте металл!",
]

var max_metal_training_complete_steps: Array[String] = [
	"Капитан, вы молодец, справились! Теперь можно спокойно играть!",
]

var full_cycle_training_complete_steps: Array[String] = [
	"Обучение закончено. Капитан, вы молодец, справились! Возвращаю вас на главный экран.",
]

var training_defeat_steps: Array[String] = [
	"Капитан, обучение прервано: корабль не пережил атаку. Возвращаю вас на главный экран, попробуем снова.",
]

var max_metal_training_intro_steps: Array[String] = [
	"Капитан, это тренировочный режим. Наберите максимум [color=orange]МЕТАЛЛА[/color], и я проверю ваш первый рубеж!",
]

# ========== СИСТЕМНЫЕ ПЕРЕМЕННЫЕ ==========
var dialog_queue: Array[Array] = [] # Очередь диалогов
var tutorial_steps: Array[String] = []
var current_step: int = 0
var is_typing: bool = false
var highlight_tween: Tween
var _typing_session_id: int = 0

# Флаги состояний и паузы
var _pause_state_before_tutorial: bool = false
var _pause_applied: bool = false
var _raider_warning_shown: bool = false
var _raider_defense_shown: bool = false
var _shop_invite_shown: bool = false
var _shop_guide_shown: bool = false
var _reactor_guide_shown: bool = false
var _max_resources_shown_times: int = 0
var _tutorial_disabled_for_profile: bool = false
var _tutorial_started: bool = false
var _training_redirect_scheduled: bool = false
var _training_failed: bool = false
var _tutorial_first_raider_requested: bool = false
var _training_finish_scheduled: bool = false
var _training_raider_warning_done: bool = false
var _training_raider_defense_done: bool = false
var _training_shop_invite_done: bool = false
var _training_shop_guide_done: bool = false
var _training_reactor_guide_done: bool = false
var _training_max_resources_done: bool = false

const START_MENU_SCENE: String = "res://ui/start_menu.tscn"
const FIRST_RAIDER_REQUEST_DELAY_SEC: float = 0.25

# Флаг для защиты от закликивания (анти-скип)
var _is_input_blocked: bool = false
var _focused_target_id: String = ""
var _focused_target_rect: Rect2 = Rect2()
var _step_allows_target_interaction: bool = false
var _step_action_id: String = ""
var _focus_cutout_panels: Array[ColorRect] = []
var _cutout_layer: CanvasLayer = null  # Слой для затемнения (layer = -1)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Работаем даже при паузе
	hide()
	dialog_text.bbcode_enabled = true
	dialog_text.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	if tutorial_mode == TutorialMode.FULL and not ignore_save_flags:
		_tutorial_disabled_for_profile = SaveManager.is_tutorial_shown(TUTORIAL_ID_NADYA_ONE_TIME)
		if _tutorial_disabled_for_profile:
			return
	
	# Восстанавливаем обычное затемнение - полный экран
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.visible = true
	
	GameEvents.max_resources_reached.connect(_on_max_resources_reached)
	GameEvents.game_finished.connect(_on_game_finished)
	GameEvents.tutorial_target_rect_changed.connect(_on_tutorial_target_rect_changed)

	if tutorial_mode == TutorialMode.FULL or tutorial_mode == TutorialMode.FULL_CYCLE_TRAINING:
		GameEvents.raider_spawned.connect(_on_raider_spawned)
		GameEvents.raider_destroyed.connect(_on_raider_destroyed)
		GameEvents.resource_changed.connect(_on_resource_changed)
		GameEvents.shop_opened.connect(_on_shop_opened)
	
	# Автостарт оставляем на случай, если сцена запущена без main.gd-контроллера.
	get_tree().create_timer(0.5, true, false, true).timeout.connect(start_tutorial)

func start_tutorial() -> void:
	if _tutorial_started:
		return
	if _tutorial_disabled_for_profile:
		return
	_tutorial_started = true

	if tutorial_mode == TutorialMode.MAX_METAL_TRAINING:
		_queue_dialog(max_metal_training_intro_steps)
		return

	_queue_dialog(intro_steps)
	_queue_dialog(gathering_steps)
	_try_queue_training_dialogs_from_current_state()

# ========== ЛОГИКА ОЧЕРЕДИ ==========
func _queue_dialog(steps: Array[String]) -> void:
	if _tutorial_disabled_for_profile:
		return
	if steps.is_empty(): 
		return
	dialog_queue.append(steps)
	if not visible:
		_play_next_dialog()

func _play_next_dialog() -> void:
	if dialog_queue.is_empty():
		_hide_and_unpause()
		return
		
	if not _pause_applied:
		var tree := get_tree()
		_pause_state_before_tutorial = tree.paused if tree != null else false
		_set_tree_paused_safe(true)
		_pause_applied = true
		
	tutorial_steps = dialog_queue.pop_front()
	current_step = 0
	show()
	_show_current_step()

func _hide_and_unpause() -> void:
	hide()
	_clear_focus_target()
	if _pause_applied:
		_set_tree_paused_safe(_pause_state_before_tutorial)
		_pause_applied = false

func _show_current_step() -> void:
	if current_step >= tutorial_steps.size():
		_on_dialog_finished(tutorial_steps)
		_play_next_dialog()
		return

	# Включаем защиту от случайных кликов на 0.5 секунд
	_is_input_blocked = true
	get_tree().create_timer(0.5, true, false, true).timeout.connect(func(): _is_input_blocked = false)

	# Сбрасываем цвет перед новой репликой
	dialog_text.modulate = Color.WHITE
	if highlight_tween:
		highlight_tween.kill()

	_apply_focus_for_current_step()

	dialog_panel.custom_minimum_size.y = BASE_DIALOG_PANEL_HEIGHT
	is_typing = true
	dialog_text.text = tutorial_steps[current_step]
	dialog_text.visible_characters = 0
	call_deferred("_start_typewriter")

func _start_highlight_animation() -> void:
	if highlight_tween:
		highlight_tween.kill()
	highlight_tween = create_tween()
	highlight_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	highlight_tween.set_loops()
	highlight_tween.set_ease(Tween.EASE_IN_OUT)
	highlight_tween.set_trans(Tween.TRANS_SINE)
	highlight_tween.tween_property(dialog_text, "modulate", Color(1.2, 1.2, 1.2), 1.0)
	highlight_tween.tween_property(dialog_text, "modulate", Color(1.0, 1.0, 1.0), 1.0)

# ========== РЕАКЦИИ НА ИГРОВЫЕ СОБЫТИЯ ==========
func _on_game_started() -> void:
	start_tutorial()

func _mark_tutorial_completed_once() -> void:
	if _tutorial_disabled_for_profile:
		return
	if SaveManager.is_tutorial_shown(TUTORIAL_ID_NADYA_ONE_TIME):
		_tutorial_disabled_for_profile = true
		return
	SaveManager.mark_tutorial_shown(TUTORIAL_ID_NADYA_ONE_TIME)
	_tutorial_disabled_for_profile = true

func _on_dialog_finished(finished_steps: Array[String]) -> void:
	if finished_steps == gathering_steps and (tutorial_mode == TutorialMode.FULL or tutorial_mode == TutorialMode.FULL_CYCLE_TRAINING):
		_request_first_raider_for_tutorial()

	if tutorial_mode == TutorialMode.FULL:
		if finished_steps == shop_guide_steps:
			_mark_tutorial_completed_once()
		return

	if tutorial_mode == TutorialMode.FULL_CYCLE_TRAINING:
		_mark_training_step_done(finished_steps)
		if finished_steps == training_defeat_steps:
			_schedule_return_to_main_menu()
			return
		if finished_steps == full_cycle_training_complete_steps:
			_schedule_return_to_main_menu()
			return
		_try_queue_training_dialogs_from_current_state()
		_try_schedule_full_cycle_finish()
		return

	if tutorial_mode == TutorialMode.MAX_METAL_TRAINING:
		if finished_steps == training_defeat_steps:
			_schedule_return_to_main_menu()

func _on_raider_spawned(_position: Vector2) -> void:
	if tutorial_mode != TutorialMode.FULL and tutorial_mode != TutorialMode.FULL_CYCLE_TRAINING:
		return
	if _raider_warning_shown: 
		return
	_raider_warning_shown = true
	await get_tree().create_timer(1.5, true, false, true).timeout
	_queue_dialog(raider_warning_steps)

func _on_resource_changed(type: String, new_amount: int) -> void:
	if tutorial_mode != TutorialMode.FULL and tutorial_mode != TutorialMode.FULL_CYCLE_TRAINING:
		return
	if type == "metal":
		if new_amount >= 75 and not _shop_invite_shown:
			_shop_invite_shown = true
			_queue_dialog(shop_invite_steps)
			
		if new_amount >= 375 and not _reactor_guide_shown:
			_reactor_guide_shown = true
			_queue_dialog(reactor_guide_steps)

		if tutorial_mode == TutorialMode.FULL_CYCLE_TRAINING and new_amount >= ResourceManager.max_metal and not _training_max_resources_done and _max_resources_shown_times < 1:
			_max_resources_shown_times = 1
			_queue_dialog(max_resources_steps)

	if tutorial_mode == TutorialMode.FULL_CYCLE_TRAINING:
		_try_queue_training_dialogs_from_current_state()

func _on_shop_opened() -> void:
	if tutorial_mode != TutorialMode.FULL and tutorial_mode != TutorialMode.FULL_CYCLE_TRAINING:
		return
	if not _shop_guide_shown and ResourceManager.metal >= 75:
		_shop_guide_shown = true
		_queue_dialog(shop_guide_steps)

	if tutorial_mode == TutorialMode.FULL_CYCLE_TRAINING:
		_try_queue_training_dialogs_from_current_state()

func _on_max_resources_reached(resource_type: String, _max_amount: int) -> void:
	if tutorial_mode == TutorialMode.MAX_METAL_TRAINING:
		if _max_resources_shown_times >= 1:
			return
		_max_resources_shown_times = 1
		if resource_type == "metal":
			_queue_dialog([max_resources_steps[0]])
			_queue_dialog(max_metal_training_complete_steps)
		return

	if tutorial_mode == TutorialMode.FULL_CYCLE_TRAINING:
		if resource_type != "metal":
			return
		if _training_max_resources_done or _max_resources_shown_times >= 1:
			return
		_max_resources_shown_times = 1
		_queue_dialog(max_resources_steps)
		return

	if _max_resources_shown_times < 2:
		_max_resources_shown_times += 1
		print("DEBUG: Max resources reached times: ", _max_resources_shown_times)
		_queue_dialog(max_resources_steps)

func _on_raider_destroyed(_position: Vector2, _evolution_level: int, _source: String) -> void:
	if tutorial_mode != TutorialMode.FULL and tutorial_mode != TutorialMode.FULL_CYCLE_TRAINING:
		return
	if _raider_warning_shown and not _raider_defense_shown:
		_raider_defense_shown = true
		_queue_dialog(raider_defense_steps)

	if tutorial_mode == TutorialMode.FULL_CYCLE_TRAINING:
		_try_queue_training_dialogs_from_current_state()

func _on_game_finished(outcome: String, _reason: String) -> void:
	if outcome == "lose":
		if tutorial_mode == TutorialMode.FULL_CYCLE_TRAINING or tutorial_mode == TutorialMode.MAX_METAL_TRAINING:
			_training_failed = true
			dialog_queue.clear()
			_queue_dialog(training_defeat_steps)
			return

		var defeat_steps: Array[String] = [
			"КАПИТАН, МЫ ПОТЕРПЕЛИ ПОРАЖЕНИЕ! АКТИВИРУЮ РЕЖИМ ПОСЛЕДНЕЙ НАДЕЖДЫ...",
		]
		dialog_queue.clear()
		_queue_dialog(defeat_steps)

func _request_first_raider_for_tutorial() -> void:
	if _training_failed:
		return
	if _raider_warning_shown:
		return
	if _tutorial_first_raider_requested:
		return
	_tutorial_first_raider_requested = true
	call_deferred("_emit_raider_spawn_request_after_delay")

func _emit_raider_spawn_request_after_delay() -> void:
	await get_tree().create_timer(FIRST_RAIDER_REQUEST_DELAY_SEC, true, false, true).timeout
	if _training_failed:
		return
	if _raider_warning_shown:
		return
	GameEvents.tutorial_raider_spawn_requested.emit()


func _mark_training_step_done(finished_steps: Array[String]) -> void:
	if finished_steps == raider_warning_steps:
		_training_raider_warning_done = true
	elif finished_steps == raider_defense_steps:
		_training_raider_defense_done = true
	elif finished_steps == shop_invite_steps:
		_training_shop_invite_done = true
	elif finished_steps == shop_guide_steps:
		_training_shop_guide_done = true
	elif finished_steps == reactor_guide_steps:
		_training_reactor_guide_done = true
	elif finished_steps == max_resources_steps:
		_training_max_resources_done = true


func _try_queue_training_dialogs_from_current_state() -> void:
	if tutorial_mode != TutorialMode.FULL_CYCLE_TRAINING:
		return
	if _training_failed:
		return

	if ResourceManager.metal >= 75 and not _shop_invite_shown:
		_shop_invite_shown = true
		_queue_dialog(shop_invite_steps)

	if ResourceManager.metal >= 375 and not _reactor_guide_shown:
		_reactor_guide_shown = true
		_queue_dialog(reactor_guide_steps)

	if ResourceManager.metal >= ResourceManager.max_metal and not _training_max_resources_done and _max_resources_shown_times < 1:
		_max_resources_shown_times = 1
		_queue_dialog(max_resources_steps)


func _try_schedule_full_cycle_finish() -> void:
	if tutorial_mode != TutorialMode.FULL_CYCLE_TRAINING:
		return
	if _training_failed:
		return
	if _training_finish_scheduled:
		return

	var all_warning_types_done: bool = \
		_training_raider_warning_done and \
		_training_raider_defense_done and \
		_training_shop_invite_done and \
		_training_shop_guide_done and \
		_training_reactor_guide_done and \
		_training_max_resources_done

	if not all_warning_types_done:
		return

	_training_finish_scheduled = true
	_queue_dialog(full_cycle_training_complete_steps)

func _schedule_return_to_main_menu() -> void:
	if _training_redirect_scheduled:
		return
	_training_redirect_scheduled = true
	_return_to_main_menu()

func _return_to_main_menu() -> void:
	_set_tree_paused_safe(false)
	if ResourceLoader.exists(START_MENU_SCENE):
		var tree := get_tree()
		if tree != null:
			tree.change_scene_to_file(START_MENU_SCENE)

func _set_tree_paused_safe(value: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = value

# ========== ГЛОБАЛЬНЫЙ ПЕРЕХВАТ КЛИКОВ ==========
func _input(event: InputEvent) -> void:
	if not visible: 
		return

	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		# Перехватываем событие, чтобы оно не просочилось в саму игру под окном Нади
		get_viewport().set_input_as_handled() 
		
		# Если блокировка активна - игнорируем нажатие
		if _is_input_blocked:
			return
		
		if is_typing:
			_typing_session_id += 1
			dialog_text.visible_characters = dialog_text.get_total_character_count()
			_fit_dialog_panel_to_visible_text()
			is_typing = false
			_start_highlight_animation()
		else:
			if _step_allows_target_interaction:
				if not _can_trigger_step_action(_extract_event_position(event)):
					return
				# Для покупки корпуса: первый клик завершает реплику, а не строит модуль.
				# Реальная постройка произойдет только следующим кликом игрока по кнопке после закрытия окна.
				if not _step_action_id.is_empty() and _step_action_id != "buy_hull":
					GameEvents.tutorial_action_requested.emit(_step_action_id)

			current_step += 1
			_show_current_step()

func _apply_focus_for_current_step() -> void:
	_clear_focus_target()

	if tutorial_steps == shop_invite_steps and current_step == 0:
		_set_focus_target("shop_button", Color(0.756863, 0.564706, 0.87451, 1.0), true, "open_shop")
		return

	if tutorial_steps != shop_guide_steps:
		return

	match current_step:
		1:
			_set_focus_target("hull", Color(0.3, 0.8, 0.3, 1.0), false)
		2:
			_set_focus_target("reactor", Color(0.95, 0.74, 0.2, 1.0), false)
		3:
			_set_focus_target("reactor", Color(0.95, 0.74, 0.2, 1.0), false)
		4:
			_set_focus_target("core", Color(0.941, 0.816, 0.125, 1.0), false)
		5:
			_set_focus_target("collector", Color(1.0, 0.9, 0.2, 1.0), false)
		6:
			_set_focus_target("turret", Color(0.95, 0.32, 0.18, 1.0), false)
		7:
			_set_focus_target("core", Color(0.941, 0.816, 0.125, 1.0), false)
		8:
			_set_focus_target("hull", Color(0.3, 0.8, 0.3, 1.0), true, "buy_hull")

func _set_focus_target(target_id: String, accent_color: Color, allow_interaction: bool, action_id: String = "") -> void:
	_focused_target_id = target_id
	_step_allows_target_interaction = allow_interaction
	_step_action_id = action_id
	_focused_target_rect = Rect2()
	GameEvents.tutorial_focus_changed.emit(target_id, accent_color, allow_interaction)

func _clear_focus_target() -> void:
	_focused_target_id = ""
	_focused_target_rect = Rect2()
	_step_allows_target_interaction = false
	_step_action_id = ""
	GameEvents.tutorial_focus_cleared.emit()

func _on_tutorial_target_rect_changed(target_id: String, target_rect: Rect2) -> void:
	if target_id != _focused_target_id:
		return
	_focused_target_rect = target_rect

func _can_trigger_step_action(event_position: Vector2) -> bool:
	if _focused_target_id.is_empty():
		return false
	if _focused_target_rect.size.x <= 0.0 or _focused_target_rect.size.y <= 0.0:
		return false
	return _focused_target_rect.has_point(event_position)

func _extract_event_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	return Vector2(-10000.0, -10000.0)

func _start_typewriter() -> void:
	_typing_session_id += 1
	var session_id: int = _typing_session_id
	_run_typewriter(session_id)

func _run_typewriter(session_id: int) -> void:
	var total_chars: int = dialog_text.get_total_character_count()
	if total_chars <= 0:
		is_typing = false
		_start_highlight_animation()
		return

	while dialog_text.visible_characters < total_chars:
		if session_id != _typing_session_id or not is_typing:
			return

		var next_visible_characters: int = dialog_text.visible_characters + 1
		if _needs_expand_for_next_character(next_visible_characters):
			_expand_dialog_for_next_character(next_visible_characters)
			await get_tree().process_frame
			if session_id != _typing_session_id or not is_typing:
				return

		dialog_text.visible_characters = next_visible_characters
		await get_tree().create_timer(TYPEWRITER_CHAR_DELAY, true, false, true).timeout

	if session_id != _typing_session_id or not is_typing:
		return

	is_typing = false
	_start_highlight_animation()

func _needs_expand_for_next_character(next_visible_characters: int) -> bool:
	var current_panel_height: float = dialog_panel.custom_minimum_size.y
	var current_capacity: float = max(0.0, current_panel_height - DIALOG_CONTENT_PADDING)
	var next_content_height: float = _predict_content_height(next_visible_characters)
	return next_content_height > current_capacity + 0.5

func _expand_dialog_for_next_character(next_visible_characters: int) -> void:
	var viewport_height: float = get_viewport().get_visible_rect().size.y
	if viewport_height <= 0.0:
		return

	var current_panel_height: float = dialog_panel.custom_minimum_size.y
	var current_capacity: float = max(0.0, current_panel_height - DIALOG_CONTENT_PADDING)
	var next_content_height: float = _predict_content_height(next_visible_characters)
	var required_expand: float = max(0.0, next_content_height - current_capacity)
	if required_expand <= 0.0:
		return

	var max_dialog_height: float = viewport_height * MAX_DIALOG_HEIGHT_RATIO
	var target_height: float = min(max_dialog_height, current_panel_height + required_expand)
	dialog_panel.custom_minimum_size.y = max(BASE_DIALOG_PANEL_HEIGHT, target_height)

func _predict_content_height(visible_characters: int) -> float:
	var previous_visible_characters: int = dialog_text.visible_characters
	dialog_text.visible_characters = visible_characters
	# RichTextLabel can slightly underestimate lower glyph descenders in some fonts.
	var predicted_height: float = dialog_text.get_content_height() + TEXT_DESCENDER_PADDING
	dialog_text.visible_characters = previous_visible_characters
	return predicted_height

func _fit_dialog_panel_to_visible_text() -> void:
	var viewport_height: float = get_viewport().get_visible_rect().size.y
	if viewport_height <= 0.0:
		return

	var text_height: float = dialog_text.get_content_height() + TEXT_DESCENDER_PADDING
	var requested_height: float = max(BASE_DIALOG_PANEL_HEIGHT, text_height + DIALOG_CONTENT_PADDING)
	var max_dialog_height: float = viewport_height * MAX_DIALOG_HEIGHT_RATIO
	var target_height: float = clamp(requested_height, BASE_DIALOG_PANEL_HEIGHT, max_dialog_height)
	dialog_panel.custom_minimum_size.y = target_height

func _create_cutout_layer() -> void:
	pass  # Затемнение отключено - только подсветка

func _create_full_screen_darkening() -> void:
	pass  # Затемнение отключено

func _create_focus_cutout() -> void:
	pass  # Затемнение отключено

func _update_focus_cutout() -> void:
	pass  # Затемнение отключено

func _destroy_focus_cutout() -> void:
	for panel in _focus_cutout_panels:
		if is_instance_valid(panel):
			panel.queue_free()
	_focus_cutout_panels.clear()
