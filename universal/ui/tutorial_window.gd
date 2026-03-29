extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var dialog_text: RichTextLabel = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DialogText
@onready var name_label: Label = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NameLabel

# ========== ТЕКСТЫ ДИАЛОГОВ ==========
var intro_steps: Array[String] = [
	"Капитан, вы меня слышите? Это [color=yellow][b]Н.А.Д.Я.[/b][/color], ваша Наблюдательная Автономная Диспетчерская Ячейка.",
	"Наш корабль серьезно пострадал. Мы застряли в секторе космического мусора.",
]

var gathering_steps: Array[String] = [
	"Чтобы выжить, нам нужно собирать обломки. Нажимайте по пролетающему [color=brown][b]МУСОРУ[/b][/color], чтобы добыть [color=orange][b]МЕТАЛЛ[/b][/color]!",
]

var raider_warning_steps: Array[String] = [
	"Капитан, тревога! Это [color=red][b]ВРАГ[/b][/color]. Он хочет забрать наши ресурсы.",
    "Чтобы уничтожть врага, нажимайте по нему так быстро как только сможете"
]

var raider_defense_steps: Array[String] = [
	"Отличная работа, Капитан!",
    "Напоминаю, для автоматизации защиты от [color=red][b]ВРАГОВ[/b][/color] постройте турели: их можно купить в магазине."
]

var shop_invite_steps: Array[String] = [
    "Капитан, у вас достаточно [color=orange][b]МЕТАЛЛА[/b][/color]! Зайдите в [color=green][b]МАГАЗИН[/b][/color], чтобы купить модули для корабля."
]

var shop_guide_steps: Array[String] = [
	"Магазин открыт! Я расскажу об основных модулях, за каждый отвечает свой эффект:",
	"[color=cyan]КОРПУС[/color] — базовая защита, которая смягчает урон.",
	"[color=cyan]РЕАКТОР[/color] — источник энергии, расширяет возможности строительства.",
	"[color=cyan]СБОРЩИК[/color] — увеличивает скорость добычи металла.",
	"[color=cyan]ТУРЕЛЬ[/color] — оборонительный модуль, атакует врагов автоматически.",
    "[color=cyan]СПЕЦИАЛЬНЫЙ МОДУЛЬ[/color] — уникальный эффект: усиление урона/щит/экон. Используй по ситуации."
]
var reactor_guide_steps: Array[String] = [
	"Капитан, вы накопили [color=orange][b]375 МЕТАЛЛА[/b][/color]! Этого хватит для постройки [color=cyan]РЕАКТОРА[/color].",
    "Каждому новому отсеку нужна энергия. Постройте [color=cyan]РЕАКТОР[/color], чтобы увеличить энергоемкость корабля и продолжить расширение базы!"
]

# ========== СИСТЕМНЫЕ ПЕРЕМЕННЫЕ ==========
var dialog_queue: Array[Array] = [] # Очередь диалогов
var tutorial_steps: Array[String] = []
var current_step: int = 0
var is_typing: bool = false
var typing_tween: Tween
var highlight_tween: Tween

# Флаги состояний и паузы
var _pause_state_before_tutorial: bool = false
var _pause_applied: bool = false
var _raider_warning_shown: bool = false
var _raider_defense_shown: bool = false
var _shop_invite_shown: bool = false
var _shop_guide_shown: bool = false
var _reactor_guide_shown: bool = false

# Флаг для защиты от закликивания (анти-скип)
var _is_input_blocked: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Работаем даже при паузе
	hide()
	dialog_text.bbcode_enabled = true
	
	GameEvents.raider_spawned.connect(_on_raider_spawned)
	GameEvents.raider_destroyed.connect(_on_raider_destroyed)
	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.shop_opened.connect(_on_shop_opened)
	GameEvents.game_finished.connect(_on_game_finished)
	
	# Ждем ровно 0.5 секунды после загрузки сцены и вызываем стартовый диалог.
	get_tree().create_timer(0.5, true, false, true).timeout.connect(_on_game_started)

# ========== ЛОГИКА ОЧЕРЕДИ ==========
func _queue_dialog(steps: Array[String]) -> void:
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
		_pause_state_before_tutorial = get_tree().paused
		get_tree().paused = true
		_pause_applied = true
		
	tutorial_steps = dialog_queue.pop_front()
	current_step = 0
	show()
	_show_current_step()

func _hide_and_unpause() -> void:
	hide()
	if _pause_applied:
		get_tree().paused = _pause_state_before_tutorial
		_pause_applied = false

func _show_current_step() -> void:
	if current_step >= tutorial_steps.size():
		_play_next_dialog()
		return

	# Включаем защиту от случайных кликов на 0.5 секунд
	_is_input_blocked = true
	get_tree().create_timer(0.5, true, false, true).timeout.connect(func(): _is_input_blocked = false)

	# Сбрасываем цвет перед новой репликой
	dialog_text.modulate = Color.WHITE
	if highlight_tween:
		highlight_tween.kill()

	is_typing = true
	dialog_text.text = tutorial_steps[current_step]
	dialog_text.visible_ratio = 0.0 
	
	if typing_tween: 
		typing_tween.kill()
		
	typing_tween = create_tween()
	var duration = tutorial_steps[current_step].length() * 0.03
	typing_tween.tween_property(dialog_text, "visible_ratio", 1.0, duration)
	typing_tween.finished.connect(func(): 
		is_typing = false
		_start_highlight_animation()
	)

func _start_highlight_animation() -> void:
	if highlight_tween:
		highlight_tween.kill()
	highlight_tween = create_tween()
	highlight_tween.set_loops()
	highlight_tween.set_ease(Tween.EASE_IN_OUT)
	highlight_tween.set_trans(Tween.TRANS_SINE)
	highlight_tween.tween_property(dialog_text, "modulate", Color(1.2, 1.2, 1.2), 1.0)
	highlight_tween.tween_property(dialog_text, "modulate", Color(1.0, 1.0, 1.0), 1.0)

# ========== РЕАКЦИИ НА ИГРОВЫЕ СОБЫТИЯ ==========
func _on_game_started() -> void:
	_queue_dialog(intro_steps)
	_queue_dialog(gathering_steps)

func _on_raider_spawned(_position: Vector2) -> void:
	if _raider_warning_shown: 
		return
	_raider_warning_shown = true
	await get_tree().create_timer(1.5, true, false, true).timeout
	_queue_dialog(raider_warning_steps)

func _on_resource_changed(type: String, new_amount: int) -> void:
	if type == "metal":
		if new_amount >= 75 and not _shop_invite_shown:
			_shop_invite_shown = true
			_queue_dialog(shop_invite_steps)
			
		if new_amount >= 375 and not _reactor_guide_shown:
			_reactor_guide_shown = true
			_queue_dialog(reactor_guide_steps)

func _on_shop_opened() -> void:
	if not _shop_guide_shown and ResourceManager.metal >= 75:
		_shop_guide_shown = true
		_queue_dialog(shop_guide_steps)

func _on_raider_destroyed(_position: Vector2, _evolution_level: int, _source: String) -> void:
	if _raider_warning_shown and not _raider_defense_shown:
		_raider_defense_shown = true
		_queue_dialog(raider_defense_steps)

func _on_game_finished(outcome: String, _reason: String) -> void:
	if outcome == "lose":
		var defeat_steps: Array[String] = [
			"КАПИТАН, МЫ ПОТЕРПЕЛИ ПОРАЖЕНИЕ. КОРАБЛЬ РАЗРУШЕН.",
            "НЕ РАССТРАИВАЙТЕСЬ, ПОПРОБУЙТЕ СНОВА!"
		]
		dialog_queue.clear()
		_queue_dialog(defeat_steps)

# ========== ГЛОБАЛЬНЫЙ ПЕРЕХВАТ КЛИКОВ ==========
func _input(event: InputEvent) -> void:
	if not visible: 
		return

	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		# Перехватываем событие, чтобы оно не просочилось в саму игру под окном Нади
		get_viewport().set_input_as_handled() 
		
		# Если блокировка активна - игнорируем нажатие (но в игру оно уже не пойдет благодаря строке выше)
		if _is_input_blocked:
			return
		
		if is_typing:
			if typing_tween: 
				typing_tween.kill()
			dialog_text.visible_ratio = 1.0
			is_typing = false
			_start_highlight_animation()
		else:
			current_step += 1
			_show_current_step()
