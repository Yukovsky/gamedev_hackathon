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
const START_MENU_SCENE: String = "res://ui/start_menu.tscn"
const FIRST_RAIDER_REQUEST_DELAY_SEC: float = 0.25

const STEP_INTRO: String = "intro"
const STEP_GATHERING: String = "gathering"
const STEP_RAIDER_WARNING: String = "raider_warning"
const STEP_RAIDER_DEFENSE: String = "raider_defense"
const STEP_SHOP_INVITE: String = "shop_invite"
const STEP_SHOP_GUIDE: String = "shop_guide"
const STEP_REACTOR_GUIDE: String = "reactor_guide"
const STEP_MAX_RESOURCES: String = "max_resources"
const STEP_COMPLETE: String = "complete"
const STEP_DEFEAT: String = "defeat"

const RESOURCE_TYPE_METAL: String = "metal"

const FLOW_REQUIRED_STEP_IDS: Array[String] = [
	STEP_RAIDER_WARNING,
	STEP_RAIDER_DEFENSE,
	STEP_SHOP_INVITE,
	STEP_SHOP_GUIDE,
	STEP_REACTOR_GUIDE,
	STEP_MAX_RESOURCES,
]

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
var _base_step_lines: Dictionary = {
	STEP_INTRO: [
	"Капитан, вы меня слышите? Это [color=yellow]Н.А.Д.Я.[/color], ваша Наблюдательная Автономная Диспетчерская Ячейка.",
	"Наш корабль серьезно пострадал. Мы застряли в секторе космического мусора.",
	],
	STEP_GATHERING: [
	"Чтобы выжить, нам нужно собирать обломки. Нажимайте по пролетающему [color=brown]МУСОРУ[/color], чтобы добыть [color=orange]МЕТАЛЛ[/color]!",
	],
	STEP_RAIDER_WARNING: [
	"Капитан, тревога! Это [color=red]ВРАГ[/color]. Он хочет забрать наши ресурсы.",
	"Чтобы уничтожить врага, нажимайте по нему так быстро как только сможете",
	],
	STEP_RAIDER_DEFENSE: [
	"Отличная работа, Капитан!",
	"Напоминаю, для автоматизации защиты от [color=red]ВРАГОВ[/color] постройте ТУРЕЛИ: их можно купить в ЦЕХЕ."
	],
	STEP_SHOP_INVITE: [
	"Капитан, у вас достаточно [color=orange]МЕТАЛЛА[/color]! Нажмите на подсвеченную кнопку ⬆ внизу экрана, чтобы открыть [color=green]ЦЕХ УЛУЧШЕНИЙ[/color]."
	],
	STEP_SHOP_GUIDE: [
	"ЦЕХ открыт! Я расскажу об основных модулях. Они расположены в разных разделах навигации:",
	"[color=%s]КОРПУС[/color] (⬆ Улучшения) — увеличивает максимальное количество ресурсов." % COLOR_HULL_TEXT,
	"[color=%s]РЕАКТОР[/color] (⬆ Улучшения) — без них у нас не будет энергии для работы модулей." % COLOR_REACTOR_TEXT,
	"Реактор запитывает соседние ячейки и позволяет строить модули в них",
	"Обратите внимание, что [color=%s]РЕАКТОРЫ[/color] не должны питать [color=%s]ЯДРО[/color] и наоборот" % [COLOR_REACTOR_TEXT, COLOR_CORE_TEXT],
	"[color=%s]СБОРЩИК[/color] (⚡ Автоматизация) — автоматически добывает ближайший к вашему кораблю мусор" % COLOR_COLLECTOR_TEXT,
	"[color=%s]ТУРЕЛЬ[/color] (🛡 Оборона) — оборонительный модуль, атакует врагов автоматически." % COLOR_TURRET_TEXT,
	"[color=%s]ЯДРО[/color] (⬆ Улучшения) — увеличивает количество металла, получаемого с каждого обломка." % COLOR_CORE_TEXT,
	"Сейчас у нас хватает [color=orange]МЕТАЛЛА[/color] на [color=%s]КОРПУС[/color]. Самое время его приобрести" % COLOR_HULL_TEXT,
	"Не переживайте, я буду указывать на разрешенные места для строительства модулей",
	],
	STEP_REACTOR_GUIDE: [
	"Капитан, вы накопили [color=orange]375 МЕТАЛЛА[/color]! Этого хватит для постройки [color=cyan]РЕАКТОРА[/color].",
	"Каждому новому отсеку нужна энергия. Постройте [color=cyan]РЕАКТОР[/color], чтобы увеличить энергоемкость корабля и продолжить расширение базы!",
	"Если вам удастся построить [color=cyan]4 РЕАКТОРА[/color], нам хватит энергии для [color=cyan]ГИПЕРПРЫЖКА[/color]",
	],
	STEP_MAX_RESOURCES: [
	"Капитан! Мы накопили максимальное количество [color=orange]МЕТАЛЛА[/color]!",
	"Нам нужно потратить ресурсы на постройку модулей или апгрейдов. Направляйтесь в [color=cyan]ЦЕХ[/color] и используйте металл!",
	],
	STEP_COMPLETE: [
	"Обучение завершено. Капитан, вы готовы к выживанию в секторе.",
	],
	STEP_DEFEAT: [
	"Капитан, мы потеряли корабль. Попробуем снова.",
	],
}

var _mode_step_overrides: Dictionary = {
	TutorialMode.MAX_METAL_TRAINING: {
		STEP_INTRO: [
			"Капитан, это тренировочный режим. Наберите максимум [color=orange]МЕТАЛЛА[/color], и я проверю ваш первый рубеж!",
		],
		STEP_COMPLETE: [
			"Капитан, вы молодец, справились! Теперь можно спокойно играть!",
		],
		STEP_DEFEAT: [
			"Капитан, обучение прервано: корабль не пережил атаку. Возвращаю вас на главный экран, попробуем снова.",
		],
	},
	TutorialMode.FULL_CYCLE_TRAINING: {
		STEP_INTRO: [
			"Капитан, это тренировочный вылет. Действуем по боевому протоколу, я буду вести вас шаг за шагом.",
		],
		STEP_COMPLETE: [
			"Обучение закончено. Капитан, вы молодец, справились! Возвращаю вас на главный экран.",
		],
		STEP_DEFEAT: [
			"Капитан, обучение прервано: корабль не пережил атаку. Возвращаю вас на главный экран, попробуем снова.",
		],
	},
}

var _mode_options: Dictionary = {
	TutorialMode.FULL: {
		"use_save_flag": true,
		"return_to_menu_on_end": false,
		"full_flow": true,
	},
	TutorialMode.MAX_METAL_TRAINING: {
		"use_save_flag": false,
		"return_to_menu_on_end": true,
		"full_flow": false,
	},
	TutorialMode.FULL_CYCLE_TRAINING: {
		"use_save_flag": false,
		"return_to_menu_on_end": true,
		"full_flow": true,
	},
}

# ========== СИСТЕМНЫЕ ПЕРЕМЕННЫЕ ==========
var _queued_step_ids: Array[String] = []
var _queued_step_set: Dictionary = {}
var _current_step_id: String = ""
var _current_step_lines: Array[String] = []
var _current_line_index: int = 0
var is_typing: bool = false
var highlight_tween: Tween
var _typing_session_id: int = 0

var _pause_state_before_tutorial: bool = false
var _pause_applied: bool = false
var _raider_warning_shown: bool = false
var _raider_defense_shown: bool = false
var _shop_invite_shown: bool = false
var _shop_guide_shown: bool = false
var _reactor_guide_shown: bool = false
var _max_resources_shown: bool = false
var _tutorial_disabled_for_profile: bool = false
var _tutorial_started: bool = false
var _training_redirect_scheduled: bool = false
var _training_failed: bool = false
var _tutorial_first_raider_requested: bool = false
var _training_finish_scheduled: bool = false
var _completed_flow_steps: Dictionary = {}
var _shown_step_ids: Dictionary = {}

var _is_input_blocked: bool = false
var _focused_target_id: String = ""
var _focused_target_rect: Rect2 = Rect2()
var _step_allows_target_interaction: bool = false
var _step_action_id: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	dialog_text.bbcode_enabled = true
	dialog_text.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	if _is_save_flag_enabled() and not ignore_save_flags:
		_tutorial_disabled_for_profile = SaveManager.is_tutorial_shown(TUTORIAL_ID_NADYA_ONE_TIME)
		if _tutorial_disabled_for_profile:
			return

	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.visible = true

	GameEvents.max_resources_reached.connect(_on_max_resources_reached)
	GameEvents.game_finished.connect(_on_game_finished)
	GameEvents.tutorial_target_rect_changed.connect(_on_tutorial_target_rect_changed)
	if _uses_full_flow():
		GameEvents.raider_spawned.connect(_on_raider_spawned)
		GameEvents.raider_destroyed.connect(_on_raider_destroyed)
		GameEvents.resource_changed.connect(_on_resource_changed)
		GameEvents.shop_opened.connect(_on_shop_opened)

	get_tree().create_timer(0.5, true, false, true).timeout.connect(start_tutorial)

func start_tutorial() -> void:
	if _tutorial_started:
		return
	if _tutorial_disabled_for_profile:
		return
	_tutorial_started = true
	if tutorial_mode == TutorialMode.MAX_METAL_TRAINING:
		_queue_step(STEP_INTRO)
		return

	_queue_step(STEP_INTRO)
	_queue_step(STEP_GATHERING)
	_sync_progress_from_runtime()
	_try_schedule_completion()

func _queue_step(step_id: String) -> void:
	if _tutorial_disabled_for_profile:
		return
	if step_id.is_empty():
		return
	if _shown_step_ids.has(step_id):
		return
	if _queued_step_set.has(step_id):
		return
	if _current_step_id == step_id:
		return
	var lines: Array[String] = _resolve_step_lines(step_id)
	if lines.is_empty():
		return
	_queued_step_ids.append(step_id)
	_queued_step_set[step_id] = true
	if not visible:
		_play_next_dialog()

func _play_next_dialog() -> void:
	if _queued_step_ids.is_empty():
		_hide_and_unpause()
		return

	if not _pause_applied:
		var tree := get_tree()
		_pause_state_before_tutorial = tree.paused if tree != null else false
		_set_tree_paused_safe(true)
		_pause_applied = true

	_current_step_id = _queued_step_ids.pop_front()
	_queued_step_set.erase(_current_step_id)
	_current_step_lines = _resolve_step_lines(_current_step_id)
	_current_line_index = 0
	show()
	_show_current_step()

func _hide_and_unpause() -> void:
	hide()
	_clear_focus_target()
	if _pause_applied:
		_set_tree_paused_safe(_pause_state_before_tutorial)
		_pause_applied = false
	GameEvents.tutorial_session_ended.emit()

func _show_current_step() -> void:
	if _current_line_index >= _current_step_lines.size():
		_on_dialog_finished(_current_step_id)
		_play_next_dialog()
		return

	_is_input_blocked = true
	if is_inside_tree():
		get_tree().create_timer(0.5, true, false, true).timeout.connect(func(): _is_input_blocked = false)
	else:
		_is_input_blocked = false

	dialog_text.modulate = Color.WHITE
	if highlight_tween:
		highlight_tween.kill()

	_apply_focus_for_current_step()

	dialog_panel.custom_minimum_size.y = BASE_DIALOG_PANEL_HEIGHT
	is_typing = true
	dialog_text.text = _current_step_lines[_current_line_index]
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

func _mark_tutorial_completed_once() -> void:
	if _tutorial_disabled_for_profile:
		return
	if SaveManager.is_tutorial_shown(TUTORIAL_ID_NADYA_ONE_TIME):
		_tutorial_disabled_for_profile = true
		return
	SaveManager.mark_tutorial_shown(TUTORIAL_ID_NADYA_ONE_TIME)
	_tutorial_disabled_for_profile = true

func _on_dialog_finished(step_id: String) -> void:
	_shown_step_ids[step_id] = true
	if FLOW_REQUIRED_STEP_IDS.has(step_id):
		_completed_flow_steps[step_id] = true

	if step_id == STEP_GATHERING and _uses_full_flow():
		_request_first_raider_for_tutorial()

	if step_id == STEP_RAIDER_WARNING:
		_clear_focus_target()

	if step_id == STEP_COMPLETE:
		if _is_save_flag_enabled():
			_mark_tutorial_completed_once()
		if _should_return_to_menu_on_end():
			_schedule_return_to_main_menu()
		return

	if step_id == STEP_DEFEAT:
		if _should_return_to_menu_on_end():
			_schedule_return_to_main_menu()
		return

	if tutorial_mode == TutorialMode.MAX_METAL_TRAINING:
		return

	_sync_progress_from_runtime()
	_try_schedule_completion()

func _on_raider_spawned(_position: Vector2) -> void:
	if not _uses_full_flow():
		return
	if _raider_warning_shown:
		return
	_raider_warning_shown = true
	await get_tree().create_timer(1.5, true, false, true).timeout
	_queue_step(STEP_RAIDER_WARNING)

func _on_resource_changed(type: String, new_amount: int) -> void:
	if not _uses_full_flow():
		return
	if type != RESOURCE_TYPE_METAL:
		return

	if new_amount >= 75 and not _shop_invite_shown:
		_shop_invite_shown = true
		_queue_step(STEP_SHOP_INVITE)

	if new_amount >= 375 and not _reactor_guide_shown:
		_reactor_guide_shown = true
		_queue_step(STEP_REACTOR_GUIDE)

	if new_amount >= ResourceManager.max_metal and not _max_resources_shown:
		_max_resources_shown = true
		_queue_step(STEP_MAX_RESOURCES)

	_try_schedule_completion()

func _on_shop_opened() -> void:
	if not _uses_full_flow():
		return
	if not _shop_guide_shown and ResourceManager.metal >= 75:
		_shop_guide_shown = true
		_queue_step(STEP_SHOP_GUIDE)
	_try_schedule_completion()

func _on_max_resources_reached(resource_type: String, _max_amount: int) -> void:
	if resource_type != RESOURCE_TYPE_METAL:
		return

	if tutorial_mode == TutorialMode.MAX_METAL_TRAINING:
		_queue_step(STEP_MAX_RESOURCES)
		_queue_step(STEP_COMPLETE)
		return

	if not _uses_full_flow():
		return

	if not _max_resources_shown:
		_max_resources_shown = true
		_queue_step(STEP_MAX_RESOURCES)
	_try_schedule_completion()

func _on_raider_destroyed(_position: Vector2, _evolution_level: int, _source: String) -> void:
	if not _uses_full_flow():
		return
	if _raider_warning_shown and not _raider_defense_shown:
		_raider_defense_shown = true
		_queue_step(STEP_RAIDER_DEFENSE)
	_try_schedule_completion()

func _on_game_finished(outcome: String, _reason: String) -> void:
	if outcome != "lose":
		return
	_training_failed = true
	_queued_step_ids.clear()
	_queued_step_set.clear()
	_queue_step(STEP_DEFEAT)

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

func _sync_progress_from_runtime() -> void:
	if not _uses_full_flow():
		return
	if _training_failed:
		return

	if ResourceManager.metal >= 75 and not _shop_invite_shown:
		_shop_invite_shown = true
		_queue_step(STEP_SHOP_INVITE)

	if ResourceManager.metal >= 375 and not _reactor_guide_shown:
		_reactor_guide_shown = true
		_queue_step(STEP_REACTOR_GUIDE)

	if ResourceManager.metal >= ResourceManager.max_metal and not _max_resources_shown:
		_max_resources_shown = true
		_queue_step(STEP_MAX_RESOURCES)

func _try_schedule_completion() -> void:
	if not _uses_full_flow():
		return
	if _training_failed:
		return
	if _training_finish_scheduled:
		return
	for required_id in FLOW_REQUIRED_STEP_IDS:
		if not _completed_flow_steps.has(required_id):
			return
	if _shown_step_ids.has(STEP_COMPLETE) or _queued_step_set.has(STEP_COMPLETE) or _current_step_id == STEP_COMPLETE:
		return
	_training_finish_scheduled = true
	_queue_step(STEP_COMPLETE)

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

func _resolve_step_lines(step_id: String) -> Array[String]:
	var mode_overrides: Dictionary = _mode_step_overrides.get(tutorial_mode, {})
	var source: Variant = null
	if mode_overrides.has(step_id):
		source = mode_overrides[step_id]
	elif _base_step_lines.has(step_id):
		source = _base_step_lines[step_id]

	var resolved: Array[String] = []
	if source is Array:
		for line_any in source:
			resolved.append(str(line_any))
	return resolved

func _uses_full_flow() -> bool:
	return bool(_mode_options.get(tutorial_mode, {}).get("full_flow", true))

func _should_return_to_menu_on_end() -> bool:
	return bool(_mode_options.get(tutorial_mode, {}).get("return_to_menu_on_end", false))

func _is_save_flag_enabled() -> bool:
	return bool(_mode_options.get(tutorial_mode, {}).get("use_save_flag", false))

func _set_tree_paused_safe(value: bool) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = value
func _input(event: InputEvent) -> void:
	if not visible: 
		return

	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		get_viewport().set_input_as_handled() 

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
				if not _step_action_id.is_empty() and _step_action_id != "buy_hull":
					GameEvents.tutorial_action_requested.emit(_step_action_id)

			_current_line_index += 1
			_show_current_step()

func _apply_focus_for_current_step() -> void:
	_clear_focus_target()

	if _current_step_id == STEP_RAIDER_WARNING:
		_set_focus_target("first_raider", Color(1.0, 0.18, 0.18, 1.0), false)
		return

	if _current_step_id == STEP_SHOP_INVITE and _current_line_index == 0:
		_set_focus_target("shop_button", Color(0.756863, 0.564706, 0.87451, 1.0), true, "open_shop")
		return

	if _current_step_id != STEP_SHOP_GUIDE:
		return

	match _current_line_index:
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
