extends Node
class_name HealthComponent
## Универсальный компонент здоровья для любых сущностей.
## Используется через композицию: добавьте как дочерний узел.
## Сигналы идут ВВЕРХ по иерархии (Signals Up).

signal damaged(amount: int, current_hp: int, max_hp: int, source: String)
signal healed(amount: int, current_hp: int, max_hp: int)
signal died(source: String)
signal hp_changed(current_hp: int, max_hp: int)

@export var max_hp: int = 100
@export var initial_hp: int = -1  # -1 означает использовать max_hp

var current_hp: int = 0
var _is_dead: bool = false


func _ready() -> void:
	if initial_hp < 0:
		current_hp = max_hp
	else:
		current_hp = clampi(initial_hp, 0, max_hp)
	
	hp_changed.emit(current_hp, max_hp)


func take_damage(amount: int, source: String = "unknown") -> bool:
	if _is_dead:
		return false
	
	var damage: int = maxi(0, amount)
	if damage <= 0:
		return false
	
	current_hp = maxi(0, current_hp - damage)
	damaged.emit(damage, current_hp, max_hp, source)
	hp_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		_is_dead = true
		died.emit(source)
		return true
	
	return false


func heal(amount: int) -> void:
	if _is_dead:
		return
	
	var heal_amount: int = maxi(0, amount)
	if heal_amount <= 0:
		return
	
	var old_hp: int = current_hp
	current_hp = mini(current_hp + heal_amount, max_hp)
	var actual_heal: int = current_hp - old_hp
	
	if actual_heal > 0:
		healed.emit(actual_heal, current_hp, max_hp)
		hp_changed.emit(current_hp, max_hp)


func set_max_hp(new_max: int, heal_to_full: bool = false) -> void:
	max_hp = maxi(1, new_max)
	if heal_to_full:
		current_hp = max_hp
	else:
		current_hp = mini(current_hp, max_hp)
	hp_changed.emit(current_hp, max_hp)


func get_hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return clampf(float(current_hp) / float(max_hp), 0.0, 1.0)


func is_dead() -> bool:
	return _is_dead


func is_alive() -> bool:
	return not _is_dead


func reset(to_full: bool = true) -> void:
	_is_dead = false
	if to_full:
		current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
