extends Node
class_name RaiderCombatComponent
## Компонент боя рейдера — кусание модулей и получение урона.

signal bite_started()
signal bite_executed(target: ModuleBase, success: bool)
signal damage_taken(current_hp: int, max_hp: int)
signal died(source: String)

@export var bite_delay_sec: float = 0.85
@export var bite_damage: int = 54
@export var max_hp: int = 180
@export var player_tap_damage: int = 42

var _current_hp: int = 0
var _is_biting: bool = false
var _bite_timer: Timer
var _pending_target: ModuleBase
var _board: Node


func _ready() -> void:
	_current_hp = maxi(1, max_hp)
	
	_bite_timer = Timer.new()
	_bite_timer.one_shot = true
	_bite_timer.wait_time = maxf(0.1, bite_delay_sec)
	_bite_timer.timeout.connect(_on_bite_timeout)
	add_child(_bite_timer)


func set_board(board: Node) -> void:
	_board = board


func configure_hp(hp: int) -> void:
	max_hp = maxi(1, hp)
	_current_hp = max_hp


func configure_bite(delay: float, damage: int) -> void:
	bite_delay_sec = maxf(0.1, delay)
	bite_damage = maxi(1, damage)
	if _bite_timer != null:
		_bite_timer.wait_time = bite_delay_sec


func configure_tap_damage(damage: int) -> void:
	player_tap_damage = maxi(1, damage)


func is_biting() -> bool:
	return _is_biting


func start_bite(target: ModuleBase) -> void:
	if _is_biting:
		return
	
	_is_biting = true
	_pending_target = target
	bite_started.emit()
	_bite_timer.start()


func _on_bite_timeout() -> void:
	var target: ModuleBase = _pending_target
	var bite_success: bool = false
	
	if target != null and is_instance_valid(target) and _board != null:
		if _board.has_method("try_bite_module"):
			bite_success = bool(_board.call("try_bite_module", target, bite_damage))
	
	bite_executed.emit(target, bite_success)
	_is_biting = false
	_pending_target = null


func take_damage(amount: int, source: String = "unknown") -> bool:
	## Возвращает true, если рейдер умер.
	var damage: int = maxi(1, amount)
	_current_hp = maxi(0, _current_hp - damage)
	
	damage_taken.emit(_current_hp, max_hp)
	
	if _current_hp <= 0:
		died.emit(source)
		return true
	
	return false


func take_tap_damage() -> bool:
	return take_damage(player_tap_damage, "tap")


func get_hp() -> int:
	return _current_hp


func get_max_hp() -> int:
	return max_hp


func get_hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return clampf(float(_current_hp) / float(max_hp), 0.0, 1.0)


func is_alive() -> bool:
	return _current_hp > 0
