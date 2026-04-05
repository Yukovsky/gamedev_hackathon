extends Node
## Глобальная шина событий (Event Bus) для всех систем игры.
## Главный принцип архитектуры: никаких прямых ссылок между модулями!
## Все взаимодействие происходит через сигналы этого синглтона.
##
## Используется как Autoload (GameEvents).
##
## Пример использования:
## @code
## # Отправка события
## GameEvents.garbage_clicked.emit(10)
##
## # Подписка на событие
## GameEvents.resource_changed.connect(_on_resource_changed)
## @endcode

# ========== Сигналы взаимодействия с ресурсами ==========

## Игрок тапнул по мусору и собрал его.
## @param amount: Количество собранного металла.
signal garbage_clicked(amount: int)

## Ресурсы игрока изменились.
## @param type: Тип ресурса ("metal", "energy").
## @param new_total: Новое значение ресурса.
signal resource_changed(type: String, new_total: int)

## Попытка собрать ресурс уперлась в лимит.
## @param type: Тип ресурса.
## @param current_total: Текущее значение ресурса.
## @param max_total: Максимальное значение ресурса.
signal resource_cap_reached(type: String, current_total: int, max_total: int)

## Максимум ресурсов достигнут в первый раз.
## @param resource_type: Тип ресурса.
## @param max_amount: Максимальное значение.
signal max_resources_reached(resource_type: String, max_amount: int)

# ========== Сигналы модулей ==========

## Запрос на постройку модуля.
## @param module_type: Тип модуля (см. Constants.MODULE_*).
## @param position: Позиция для постройки (Vector2.ZERO для режима выбора).
signal build_requested(module_type: String, position: Vector2)

## Режим постройки включен/выключен.
## @param is_active: true если режим постройки активен.
signal build_mode_changed(is_active: bool)

## Режим постройки отменен (например, клик по невалидному месту).
## @param module_type: Тип модуля, постройка которого была отменена.
signal build_mode_cancelled(module_type: String)

## Модуль успешно построен.
## @param module_type: Тип построенного модуля.
## @param position: Позиция в сетке.
signal module_built(module_type: String, position: Vector2)

## Модуль разрушен.
## @param module_type: Тип уничтоженного модуля.
## @param position: Позиция в сетке.
signal module_destroyed(module_type: String, position: Vector2)

## Модуль получил урон.
## @param module_type: Тип модуля.
## @param current_hp: Текущее здоровье.
## @param max_hp: Максимальное здоровье.
## @param position: Позиция в сетке.
## @param source: Источник урона ("raider", "tap", "collapse").
signal module_damaged(module_type: String, current_hp: int, max_hp: int, position: Vector2, source: String)

## Запрос на ремонт поврежденных модулей.
signal repair_requested()

# ========== Сигналы улучшений ==========

## Улучшение куплено.
## @param upgrade_id: ID улучшения (см. Constants.UPGRADE_*).
## @param new_level: Новый уровень улучшения.
signal upgrade_purchased(upgrade_id: String, new_level: int)

# ========== Сигналы игрового состояния ==========

## Игра начата.
signal game_started

## Игра закончена (устаревший, используйте game_finished).
signal game_ended

## Финальный результат игры.
## @param outcome: "win" | "lose".
## @param reason: Код причины (например: "reactors_4", "core_eaten_by_raiders").
signal game_finished(outcome: String, reason: String)

## Защита корабля изменилась.
## @param new_total: Новое значение защиты.
signal defence_changed(new_total: int)

## Разрешение столкновения с врагом.
signal collision_resolved(hazard_class: int, success: bool, modules_lost: int, discounted_builds: int)

# ========== Сигналы налётчиков ==========

## Налетчик получил урон.
## @param current_hp: Текущее HP налётчика.
## @param max_hp: Максимальное HP.
## @param position: Позиция в мире.
signal raider_damaged(current_hp: int, max_hp: int, position: Vector2)

## Налетчик уничтожен.
## @param position: Позиция в мире.
## @param evolution_level: Уровень эволюции (0 для обычного).
## @param source: Источник уничтожения ("turret", "tap").
signal raider_destroyed(position: Vector2, evolution_level: int, source: String)

## Налетчик появился на экране.
## @param position: Позиция спавна.
signal raider_spawned(position: Vector2)

## Налетчик кусает модуль.
## @param position: Позиция укуса.
signal raider_bite(position: Vector2)

## Туториал просит гарантированно заспавнить первого налетчика.
signal tutorial_raider_spawn_requested

# ========== Сигналы магазина ==========

## Магазин открыт.
signal shop_opened

## Магазин закрыт.
signal shop_closed

# ========== Сигналы туториала ==========

## Туториал: подсветить/сфокусировать конкретный UI-элемент.
## @param target_id: Логический ID цели (например: "shop_button", "hull").
## @param accent_color: Цвет акцента для подсветки.
## @param allow_interaction: Разрешено ли действие по клику по целевому элементу.
signal tutorial_focus_changed(target_id: String, accent_color: Color, allow_interaction: bool)

## Туториал: снять подсветку со всех UI-элементов.
signal tutorial_focus_cleared

## UI сообщает актуальную глобальную область целевого элемента.
## @param target_id: ID цели.
## @param target_rect: Глобальный прямоугольник элемента.
signal tutorial_target_rect_changed(target_id: String, target_rect: Rect2)

## Туториал запрашивает действие, эквивалентное нажатию на UI-элемент.
## @param action_id: ID действия (например: "open_shop", "buy_hull").
signal tutorial_action_requested(action_id: String)

# ========== Сигналы сохранения ==========

## Запрос на сохранение игры.
signal save_requested

## Запрос на загрузку игры.
signal load_requested

## Данные загружены и готовы к применению.
## @param data: Словарь с данными сохранения.
signal save_data_loaded(data: Dictionary)
