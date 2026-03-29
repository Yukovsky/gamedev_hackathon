extends Node
## Глобальная шина событий (Event Bus) для всех систем игры.
## Главный принцип: никаких прямых ссылок между модулями!
## Все взаимодействие происходит через сигналы.

# ========== Сигналы взаимодействия ==========

## Игрок тапнул по мусору
signal garbage_clicked(amount: int)

## Ресурсы изменились (металл, энергия)
signal resource_changed(type: String, new_total: int)

## Улучшение куплено
signal upgrade_purchased(upgrade_id: String, new_level: int)

## Запрос на постройку модуля
signal build_requested(module_type: String, position: Vector2)

## Режим постройки отменен (например, клик по невалидному месту)
signal build_mode_cancelled(module_type: String)

## Модуль построен
signal module_built(module_type: String, position: Vector2)

## Модуль разрушен
signal module_destroyed(module_type: String, position: Vector2)

## Модуль получил урон
signal module_damaged(module_type: String, current_hp: int, max_hp: int, position: Vector2, source: String)

## Игра начата
signal game_started

## Игра закончена
signal game_ended

## Финальный результат игры
## outcome: "win" | "lose"
## reason: произвольный код причины (например: "reactors_4", "core_eaten_by_raiders")
signal game_finished(outcome: String, reason: String)

## Защита корабля изменилась
signal defence_changed(new_total: int)

## Разрешение столкновения с врагом
signal collision_resolved(hazard_class: int, success: bool, modules_lost: int, discounted_builds: int)

## Налетчик получил урон
signal raider_damaged(current_hp: int, max_hp: int, position: Vector2)

## Налетчик уничтожен
signal raider_destroyed(position: Vector2, evolution_level: int, source: String)

## Налетчик появился
signal raider_spawned(position: Vector2)

## Налетчик кусает модуль
signal raider_bite(position: Vector2)

## Туториал просит гарантированно заспавнить первого налетчика
signal tutorial_raider_spawn_requested

## Магазин открыт
signal shop_opened

## Магазин закрыт
signal shop_closed

## Максимум ресурсов достигнут в первый раз
signal max_resources_reached(resource_type: String, max_amount: int)

## Туториал: подсветить/сфокусировать конкретный UI-элемент
## target_id: логический ID цели (например: "shop_button", "hull")
## accent_color: цвет акцента для подсветки
## allow_interaction: разрешено ли действие по клику по целевому элементу
signal tutorial_focus_changed(target_id: String, accent_color: Color, allow_interaction: bool)

## Туториал: снять подсветку со всех UI-элементов
signal tutorial_focus_cleared

## UI сообщает актуальную глобальную область целевого элемента
signal tutorial_target_rect_changed(target_id: String, target_rect: Rect2)

## Туториал запрашивает действие, эквивалентное нажатию на UI-элемент
signal tutorial_action_requested(action_id: String)
