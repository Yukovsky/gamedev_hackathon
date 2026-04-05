extends Node2D
class_name ModuleBase
## Базовый класс для всех модулей корабля.
## Предоставляет общую функциональность: HP, кликабельность, визуализация.
## Используйте наследование для создания конкретных типов модулей.

const HEALTH_COMPONENT_SCRIPT: Script = preload("res://shared/components/health_component.gd")
const HP_BAR_RENDERER_SCRIPT: Script = preload("res://shared/components/hp_bar_renderer.gd")

signal destroy_requested(module: ModuleBase, source: String)
signal hp_changed(module: ModuleBase, current_hp: int, max_hp: int, source: String)

## Уникальный идентификатор типа модуля (см. Constants.MODULE_*).
@export var module_id: String = ""
## Размер модуля в ячейках сетки.
@export var grid_size: Vector2i = Vector2i.ONE
## Стоимость постройки в металле.
@export var metal_cost: int = 0
## Бонус к защите корабля при установке.
@export var defence_bonus: int = 0
## Радиус распространения энергии (для реакторов).
@export var energy_radius_cells: int = 0
## Направление, куда "смотрит" модуль.
@export var facing_direction: Vector2 = Vector2.UP
## Цвет заливки при отсутствии текстуры.
@export var sprite_color: Color = Color(0.55, 0.55, 0.55, 1.0)
## Текстура модуля.
@export var module_texture: Texture2D

@export_group("Durability")
## Максимальное здоровье модуля.
@export var max_hp: int = 140
## Урон от одного тапа игрока.
@export var tap_damage: int = 28
## Разрешён ли урон от тапов игрока (для отладки).
@export var allow_player_tap_damage: bool = false

## Позиция модуля в сетке (в ячейках).
var grid_position: Vector2i = Vector2i.ZERO
## Размер одной ячейки в пикселях.
var cell_size_px: float = float(GridManager.CELL_SIZE)
## Текущее здоровье модуля.
var current_hp: int = 0

var _clickable: Area2D
var _collision_shape: CollisionShape2D
var _is_build_mode_active_cached: bool = false
var _health: HealthComponent
var _hp_bar: HpBarRenderer


func _ready() -> void:
	if GameEvents.has_signal("build_mode_changed"):
		GameEvents.build_mode_changed.connect(_on_build_mode_changed)
	_ensure_health_component()
	_ensure_hp_bar_renderer()


## Конфигурирует модуль для размещения в сетке.
## Вызывается после добавления модуля в дерево сцены.
func configure(cell_pos: Vector2i, cell_size: float) -> void:
	grid_position = cell_pos
	cell_size_px = cell_size
	position = Vector2(cell_pos.x * cell_size_px, cell_pos.y * cell_size_px)
	if current_hp <= 0:
		current_hp = max(1, max_hp)
		if _health != null:
			_health.set_max_hp(max_hp, true)
	_ensure_clickable()
	_update_click_shape_size()
	_configure_hp_bar()
	queue_redraw()


## Возвращает список всех ячеек, занятых модулем.
func get_occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(grid_position.x, grid_position.x + grid_size.x):
		for y in range(grid_position.y, grid_position.y + grid_size.y):
			result.append(Vector2i(x, y))
	return result


## Возвращает центр модуля в мировых координатах.
func get_world_center() -> Vector2:
	return global_position + Vector2(grid_size.x, grid_size.y) * cell_size_px * 0.5


## Устанавливает направление, куда "смотрит" модуль.
func set_facing_direction(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()


## Наносит урон модулю.
## Возвращает true, если модуль был уничтожен.
func take_damage(amount: int, source: String = "unknown") -> bool:
	var damage: int = max(0, amount)
	if damage <= 0:
		return false

	_ensure_health_component()
	if _health == null:
		return false
	return _health.take_damage(damage, source)


## Чинит модуль до полного здоровья.
func repair() -> void:
	_ensure_health_component()
	if _health == null:
		return
	var heal_amount: int = _health.max_hp - _health.current_hp
	if heal_amount > 0:
		_health.heal(heal_amount)


## Возвращает отношение текущего HP к максимальному (0.0 - 1.0).
func get_hp_ratio() -> float:
	if _health != null:
		return _health.get_hp_ratio()
	if max_hp <= 0:
		return 0.0
	return clamp(float(current_hp) / float(max_hp), 0.0, 1.0)


func _ensure_clickable() -> void:
	if _clickable != null and is_instance_valid(_clickable):
		return

	var setup: Dictionary = ClickableSetup.create_clickable(self, _on_tapped, false)
	_clickable = setup.get("clickable") as Area2D
	_collision_shape = setup.get("collision") as CollisionShape2D


func _update_click_shape_size() -> void:
	var size: Vector2 = Vector2(grid_size.x * cell_size_px, grid_size.y * cell_size_px)
	ClickableSetup.update_rect_shape(_collision_shape, size)


func _on_tapped() -> void:
	if _is_build_mode_active():
		return
	if not allow_player_tap_damage:
		return
	take_damage(tap_damage, "tap")


func _is_build_mode_active() -> bool:
	return _is_build_mode_active_cached


func _on_build_mode_changed(is_active: bool) -> void:
	_is_build_mode_active_cached = is_active


func _ensure_health_component() -> void:
	if _health != null and is_instance_valid(_health):
		return

	var existing: Node = get_node_or_null("HealthComponent")
	if existing is HealthComponent:
		_health = existing as HealthComponent
	else:
		_health = HEALTH_COMPONENT_SCRIPT.new() as HealthComponent
		_health.name = "HealthComponent"
		add_child(_health)

	_health.max_hp = max(1, max_hp)
	_health.initial_hp = max(1, current_hp) if current_hp > 0 else _health.max_hp
	_health.reset(current_hp <= 0)
	max_hp = _health.max_hp
	current_hp = _health.current_hp

	if not _health.damaged.is_connected(_on_health_damaged):
		_health.damaged.connect(_on_health_damaged)
	if not _health.died.is_connected(_on_health_died):
		_health.died.connect(_on_health_died)
	if not _health.hp_changed.is_connected(_on_health_hp_changed):
		_health.hp_changed.connect(_on_health_hp_changed)


func _on_health_damaged(_amount: int, new_hp: int, health_max_hp: int, source: String) -> void:
	current_hp = new_hp
	max_hp = health_max_hp
	hp_changed.emit(self, current_hp, max_hp, source)
	GameEvents.module_damaged.emit(module_id, current_hp, max_hp, Vector2(grid_position), source)
	queue_redraw()


func _on_health_died(source: String) -> void:
	destroy_requested.emit(self, source)


func _on_health_hp_changed(new_hp: int, health_max_hp: int) -> void:
	current_hp = new_hp
	max_hp = health_max_hp
	queue_redraw()


func _draw() -> void:
	var size_px: Vector2 = Vector2(grid_size.x * cell_size_px, grid_size.y * cell_size_px)
	var fill_rect: Rect2 = Rect2(Vector2.ZERO, size_px)

	if module_texture != null:
		draw_texture_rect(module_texture, fill_rect, false)
	else:
		draw_rect(fill_rect, sprite_color, true)
		draw_rect(fill_rect, Color(0.08, 0.08, 0.08, 1.0), false, 2.0)

	# HP bar рендерится через компонент
	if _hp_bar != null:
		_hp_bar.draw_hp_bar(self, get_hp_ratio())


func _ensure_hp_bar_renderer() -> void:
	if _hp_bar != null and is_instance_valid(_hp_bar):
		return

	var existing: Node = get_node_or_null("HpBarRenderer")
	if existing is HpBarRenderer:
		_hp_bar = existing as HpBarRenderer
	else:
		_hp_bar = HP_BAR_RENDERER_SCRIPT.new() as HpBarRenderer
		_hp_bar.name = "HpBarRenderer"
		add_child(_hp_bar)


func _configure_hp_bar() -> void:
	if _hp_bar == null:
		return
	var size_px: Vector2 = Vector2(grid_size.x * cell_size_px, grid_size.y * cell_size_px)
	_hp_bar.configure_for_module(size_px)
