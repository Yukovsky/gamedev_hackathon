extends Node
## Глобальная шина событий (Event Bus) для всех систем игры.
## Главный принцип: никаких прямых ссылок между модулями!
## Все взаимодействие происходит через сигналы.

# ========== Сигналы взаимодействия ==========

## Игрок тапнул по мусору
signal garbage_clicked(amount: int)

## Ресурсы изменились (металл, энергия)
signal resource_changed(type: String, new_total: int)

## Запрос на постройку модуля
signal build_requested(module_type: String, position: Vector2)

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
