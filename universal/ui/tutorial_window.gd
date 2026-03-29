extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var dialog_text: RichTextLabel = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DialogText
@onready var name_label: Label = $Overlay/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NameLabel

# ========== ЧАСТЬ 1: Приветствие ==========
# Показывается: При начале игры
var intro_steps: Array[String] = [
	"Капитан, вы меня слышите? Это [color=yellow][b]Н.А.Д.Я.[/b][/color], ваша Наблюдательная Автономная Диспетческая Ячейка.",
	"Наш корабль серьезно пострадал. Мы застряли в секторе космического мусора.",
]

# ========== ЧАСТЬ 2: Сбор мусора ==========
# Показывается: После приветствия (шаг 0-1)
var gathering_steps: Array[String] = [
	"Чтобы выжить, нам нужно собирать обломки. Нажимайте по пролетающему мусору, чтобы добыть [color=orange][b]МЕТАЛЛ[/b][/color]!",
]

# ========== ЧАСТЬ 3: Первый магазин (75 МЕТАЛЛ) ==========
# Показывается: При накоплении 75 МЕТАЛЛА
var phrase_3_steps: Array[String] = [
	"Отлично, Капитан! Вы собрали достаточно [color=orange][b]МЕТАЛЛА[/b][/color]. Теперь нажмите на кнопку [color=cyan][b]МАГАЗИН[/b][/color], чтобы купить модули!",
]

# ========== ЧАСТЬ 7: Реактор (375 МЕТАЛЛ) ==========
# Показывается: При накоплении 375 МЕТАЛЛА
var phrase_7_steps: Array[String] = [
	"Капитан, вы собрали ещё больше [color=orange][b]МЕТАЛЛА[/b][/color]! Пора построить [color=cyan][b]РЕАКТОР[/b][/color] - это мощный источник энергии. Откройте [color=cyan][b]МАГАЗИН[/b][/color]!",
]

# ========== ЧАСТЬ 8: Финальное напоминание ==========
# Показывается: После фразы 7
var phrase_8_steps: Array[String] = [
	"Помните, Капитан: каждое новое улучшение стоит всё дороже. Планируйте вашу стратегию. Удачи в защите нашего корабля!"
]

# ========== ЧАСТЬ 5: Предупреждение о врагах ==========
# Показывается: При появлении первого налётчика
var raider_warning_steps: Array[String] = [
	"Капитан, тревога! Это [color=red][b]враг[/b][/color]. Он хочет забрать наши ресурсы.",
	"Чтобы отбиться, кликайте прямо по [color=red][b]врагу[/b][/color], как по мусору.",
]

# ========== ЧАСТЬ 6: Защита от врагов ==========
# Показывается: После уничтожения первого врага
var raider_defense_steps: Array[String] = [
	"Капитан, для автоматизации защиты от [color=red][b]врагов[/b][/color] постройте турели: их можно купить в магазине."
]

var tutorial_steps: Array[String] = []

var current_step: int = 0
var current_tutorial_phase: int = 0  # 0=intro, 1=gathering, 2=phrase3, 3=phrase7, 4=phrase8, 5=raider_warning, 6=raider_defense
var is_typing: bool = false
var typing_tween: Tween
var _pause_state_before_tutorial: bool = false
var _pause_applied: bool = false
var _raider_warning_shown: bool = false
var _pending_raider_warning: bool = false
var shop_opened: bool = false
var _phrase_3_shown: bool = false  # Отслеживаем, показали ли фразу 3 (75 МЕТАЛЛА)
var _phrase_7_shown: bool = false  # Отслеживаем, показали ли фразу 7 (375 МЕТАЛЛА)
var _highlight_tween: Tween  # Для анимации подсвечивания кнопки
var _overlay_rect: ColorRect  # Оверлей для затемнения экрана

func _ready() -> void:
	# Диалог должен оставаться интерактивным даже когда игра на паузе.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	# Включаем BBCode для форматирования текста
	dialog_text.bbcode_enabled = true
	
	GameEvents.game_started.connect(start_tutorial)
	GameEvents.raider_spawned.connect(_on_raider_spawned)
	GameEvents.raider_destroyed.connect(_on_raider_destroyed)
	GameEvents.resource_changed.connect(_on_resource_changed)
	GameEvents.shop_opened.connect(_on_shop_opened)
	GameEvents.shop_closed.connect(_on_shop_closed)
	# Мы удалили старую подписку на gui_input, теперь все работает через _input()

func start_tutorial() -> void:
	current_tutorial_phase = 0
	_start_dialog(intro_steps)
	# После завершения intro_steps, нужно показать gathering_steps
	# Это обработается через клики пользователя


func _start_dialog(steps: Array[String]) -> void:
	if steps.is_empty():
		return

	if not _pause_applied:
		_pause_state_before_tutorial = get_tree().paused
		get_tree().paused = true
		_pause_applied = true

	tutorial_steps = steps
	show()
	current_step = 0
	_show_current_step()


func _on_raider_spawned(_position: Vector2) -> void:
	# Показываем предупреждение только после завершения основного обучения
	if current_tutorial_phase < 4:
		return
	
	if _raider_warning_shown:
		return

	_raider_warning_shown = true
	if visible:
		_pending_raider_warning = true
		return
	# Небольшая задержка, чтобы игрок успел увидеть появление врага
	await get_tree().create_timer(1.5).timeout
	# Если за это время открылся другой диалог — поставим предупреждение в очередь
	if visible:
		_pending_raider_warning = true
		return

	_start_dialog(raider_warning_steps)

func _on_resource_changed(type: String, new_amount: int) -> void:
	# Логика срабатывания фраз по количеству МЕТАЛЛА
	if type != "metal":
		return
	
	# Фраза 3: При 75 МЕТАЛЛА
	if new_amount >= 75 and not _phrase_3_shown and current_tutorial_phase == 2:
		_phrase_3_shown = true
		# остаёмся в фазе 2 до завершения диалога, затем _move_to_next_phase поднимет на 3
		current_step = 0
		# Восстанавливаем паузу для диалога
		if not _pause_applied:
			_pause_state_before_tutorial = get_tree().paused
			get_tree().paused = true
			_pause_applied = true
		_start_dialog(phrase_3_steps)
		_highlight_shop_button()

	# Фраза 7: При 375 МЕТАЛЛА
	if new_amount >= 375 and not _phrase_7_shown and current_tutorial_phase == 3:
		_phrase_7_shown = true
		# остаёмся в фазе 3 до завершения диалога, затем _move_to_next_phase поднимет на 4
		current_step = 0
		# Восстанавливаем паузу для диалога
		if not _pause_applied:
			_pause_state_before_tutorial = get_tree().paused
			get_tree().paused = true
			_pause_applied = true
		_start_dialog(phrase_7_steps)
		_highlight_shop_button()

func _show_current_step() -> void:
	if current_step >= tutorial_steps.size():
		_move_to_next_phase()
		return

	is_typing = true
	var text = tutorial_steps[current_step]
	# Текст уже содержит BBCode форматирование, просто используем его как есть
	dialog_text.text = text
	dialog_text.visible_ratio = 0.0 # Сбрасываем видимость текста в ноль
	
	if typing_tween:
		typing_tween.kill()
		
	typing_tween = create_tween()
	var duration = tutorial_steps[current_step].length() * 0.03
	typing_tween.tween_property(dialog_text, "visible_ratio", 1.0, duration)
	typing_tween.finished.connect(func(): 
		is_typing = false
		_start_highlight_animation()
	)

func _move_to_next_phase() -> void:
	"""Переход к следующей фазе обучения"""
	current_tutorial_phase += 1
	current_step = 0
	print("Переход на фазу: ", current_tutorial_phase)
	
	# Очищаем оверлей при переходе между фазами
	if _overlay_rect:
		_overlay_rect.queue_free()
		_overlay_rect = null
	
	if _highlight_tween:
		_highlight_tween.kill()
		_highlight_tween = null
	
	match current_tutorial_phase:
		0:
			# ЧАСТЬ 1: Приветствие
			_start_dialog(intro_steps)
		1:
			# ЧАСТЬ 2: Сбор мусора
			_start_dialog(gathering_steps)
		2:
			# Фраза 3 покажется при 75 МЕТАЛЛА через _on_resource_changed
			_hide_and_unpause()
		3:
			# Фраза 7 покажется при 375 МЕТАЛЛА через _on_resource_changed
			_hide_and_unpause()
		4:
			# ЧАСТЬ 8: Финальное напоминание
			_start_dialog(phrase_8_steps)
		5:
			# Ожидание враги
			_hide_and_unpause()
		6:
			# Защита
			_hide_and_unpause()
		_:
			_hide_and_unpause()

func _hide_and_unpause() -> void:
	"""Скрывает диалог и восстанавливает паузу"""
	hide()
	
	# Очищаем оверлей если он существует
	if _overlay_rect:
		_overlay_rect.queue_free()
		_overlay_rect = null
	
	# Очищаем анимацию подсвечивания если она идет
	if _highlight_tween:
		_highlight_tween.kill()
		_highlight_tween = null
	
	if _pause_applied:
		get_tree().paused = _pause_state_before_tutorial
		_pause_applied = false
	print("Диалог скрыт, пауза восстановлена")

func _on_shop_opened() -> void:
	shop_opened = true
	print("Магазин открыт. Текущая фаза: ", current_tutorial_phase)

func _on_shop_closed() -> void:
	shop_opened = false
	print("Магазин закрыт")

func _on_raider_destroyed(_position: Vector2, _evolution_level: int, _source: String) -> void:
	# Показываем советы об защите после первого уничтоженного врага
	if current_tutorial_phase == 4 and not visible:
		# Восстанавливаем паузу для диалога
		if not _pause_applied:
			_pause_state_before_tutorial = get_tree().paused
			get_tree().paused = true
			_pause_applied = true
		_start_dialog(raider_defense_steps)

func _start_highlight_animation() -> void:
	# Простая пульсация для выделенных слов (анимация цвета)
	var tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Анимируем modulate для всего текста (простая пульсация)
	tween.tween_property(dialog_text, "modulate", Color(1.2, 1.2, 1.2), 1.0)
	tween.tween_property(dialog_text, "modulate", Color(1.0, 1.0, 1.0), 1.0)

func _highlight_shop_button() -> void:
	"""Создаёт эффект затемнения и подсвечивает кнопку магазина"""
	# Очищаем старый оверлей, если существует
	if _overlay_rect:
		_overlay_rect.queue_free()
		_overlay_rect = null
	
	if _highlight_tween:
		_highlight_tween.kill()
	
	# Создаём полупрозрачный оверлей для затемнения экрана
	_overlay_rect = ColorRect.new()
	_overlay_rect.color = Color(0, 0, 0, 0)  # Начинаем с прозрачного
	_overlay_rect.anchor_left = 0
	_overlay_rect.anchor_top = 0
	_overlay_rect.anchor_right = 1
	_overlay_rect.anchor_bottom = 1
	_overlay_rect.offset_left = 0
	_overlay_rect.offset_top = 0
	_overlay_rect.offset_right = 0
	_overlay_rect.offset_bottom = 0
	
	# Добавляем оверлей перед диалогом
	add_child(_overlay_rect)
	move_child(_overlay_rect, 0)  # Понизим слой оверлея, чтобы диалог был поверх
	
	# Анимируем затемнение
	_highlight_tween = create_tween()
	_highlight_tween.tween_property(_overlay_rect, "color", Color(0, 0, 0, 0.6), 0.5)
	
	# Пытаемся найти кнопку магазина в main_ui
	var btn_shop = get_tree().root.find_child("btn_shop", true, false)
	if btn_shop:
		# Если найдена, добавляем визуальное выделение
		# Сохраняет оригинальный модулят и затем пингует её
		var original_modulate = btn_shop.modulate
		_highlight_tween = create_tween()
		_highlight_tween.set_loops()
		_highlight_tween.set_ease(Tween.EASE_IN_OUT)
		_highlight_tween.set_trans(Tween.TRANS_SINE)
		_highlight_tween.tween_property(btn_shop, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.6)
		_highlight_tween.tween_property(btn_shop, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6)
		print("Кнопка магазина подсвечена!")
	else:
		print("Кнопка магазина не найдена!")

func _end_tutorial() -> void:
	_hide_and_unpause()
	print("Фаза ", current_tutorial_phase, " обучения завершена!")
	
	# Проверяем, есть ли следующая фаза
	if current_tutorial_phase < 5:
		_move_to_next_phase()
	else:
		print("Обучение полностью завершено!")
	
	if _pending_raider_warning:
		_pending_raider_warning = false
		_start_dialog(raider_warning_steps)

# ==========================================
# ГЛОБАЛЬНЫЙ ПЕРЕХВАТ КЛИКОВ
# ==========================================
func _input(event: InputEvent) -> void:
	# Если Надя спрятана, мы вообще не вмешиваемся в клики
	if not visible:
		return

	# Проверяем, что это левый клик мыши или тап по экрану смартфона
	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		# МАГИЯ: Забираем клик себе! Теперь он не пройдет сквозь интерфейс в игру.
		get_viewport().set_input_as_handled() 
		
		if is_typing:
			# Если текст еще печатается - моментально показываем его весь
			if typing_tween:
				typing_tween.kill()
			dialog_text.visible_ratio = 1.0
			is_typing = false
		else:
			# Если текст уже напечатан - идем к следующей реплике
			current_step += 1
			_show_current_step()
