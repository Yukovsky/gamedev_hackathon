extends Node
class_name RaiderAIComponent
## Компонент ИИ рейдера — выбор цели для атаки.

signal target_acquired(target: ModuleBase)
signal target_lost()

@export var retarget_interval_sec: float = 0.35

var _board: Node
var _target: ModuleBase
var _reserved_target: ModuleBase
var _retarget_timer: Timer
var _role: int = 0  # RaiderRole enum from parent

const ROLE_NORMAL: int = 0
const ROLE_TANK: int = 1
const ROLE_SPRINTER: int = 2


func _ready() -> void:
	_retarget_timer = Timer.new()
	_retarget_timer.one_shot = false
	_retarget_timer.wait_time = maxf(0.1, retarget_interval_sec)
	_retarget_timer.timeout.connect(_on_retarget_timeout)
	add_child(_retarget_timer)
	_retarget_timer.start()


func _exit_tree() -> void:
	release_target()


func set_board(board: Node) -> void:
	_board = board


func set_role(role: int) -> void:
	_role = clamp(role, ROLE_NORMAL, ROLE_SPRINTER)


func get_target() -> ModuleBase:
	return _target


func is_target_valid() -> bool:
	return _target != null and is_instance_valid(_target)


func acquire_target() -> void:
	release_target()
	_target = null
	
	if _board == null or not _board.has_method("get_attackable_modules"):
		target_lost.emit()
		return
	
	var modules_any: Variant = _board.call("get_attackable_modules")
	if not (modules_any is Array):
		target_lost.emit()
		return
	
	var modules: Array = modules_any as Array
	if modules.is_empty():
		target_lost.emit()
		return
	
	var parent_pos: Vector2 = _get_parent_position()
	var best_priority: int = -999999
	var best_score: float = INF
	
	for candidate_any in modules:
		if not (candidate_any is ModuleBase):
			continue
		var candidate: ModuleBase = candidate_any as ModuleBase
		if not is_instance_valid(candidate):
			continue
		
		var candidate_priority: int = _get_tactical_priority(candidate)
		candidate_priority += _get_role_priority_bonus(candidate.module_id)
		
		var score: float = _calculate_target_score(candidate, parent_pos, modules.size())
		
		var is_better_priority: bool = candidate_priority > best_priority
		var is_equal_priority_better_score: bool = candidate_priority == best_priority and score < best_score
		if is_better_priority or is_equal_priority_better_score:
			best_priority = candidate_priority
			best_score = score
			_target = candidate
	
	if _target != null:
		_claim_target(_target)
		_reserved_target = _target
		target_acquired.emit(_target)
	else:
		target_lost.emit()


func release_target() -> void:
	if _reserved_target == null:
		return
	if _board != null and _board.has_method("release_module_target"):
		_board.call("release_module_target", _reserved_target)
	_reserved_target = null


func force_retarget() -> void:
	if not is_target_valid():
		acquire_target()


func _on_retarget_timeout() -> void:
	if not is_target_valid():
		acquire_target()


func _get_parent_position() -> Vector2:
	var parent: Node2D = get_parent() as Node2D
	if parent != null:
		return parent.global_position
	return Vector2.ZERO


func _get_tactical_priority(candidate: ModuleBase) -> int:
	if _board == null or not _board.has_method("get_module_tactical_priority"):
		return 0
	return int(_board.call("get_module_tactical_priority", candidate.module_id))


func _claim_target(target: ModuleBase) -> void:
	if _board != null and _board.has_method("claim_module_target"):
		_board.call("claim_module_target", target)


func _calculate_target_score(candidate: ModuleBase, from_pos: Vector2, total_modules: int) -> float:
	var distance: float = from_pos.distance_to(candidate.get_world_center())
	
	var exposure_bonus: float = 0.0
	if _board != null and _board.has_method("get_module_exposure_score"):
		var exposure: float = float(_board.call("get_module_exposure_score", candidate))
		exposure_bonus = -exposure * 48.0
	
	var hp_bias: float = 0.0
	if candidate.has_method("get_hp_ratio"):
		var hp_ratio: float = float(candidate.call("get_hp_ratio"))
		hp_bias = hp_ratio * 64.0
	
	var target_pressure_penalty: float = 0.0
	if _board != null and _board.has_method("get_target_pressure"):
		target_pressure_penalty = float(_board.call("get_target_pressure", candidate)) * 32.0
	
	var anti_core_bias: float = 0.0
	if candidate.module_id == Constants.MODULE_CORE and total_modules > 1:
		anti_core_bias = 180.0
	
	var role_bias: float = _get_role_target_bias(candidate)
	
	return distance + exposure_bonus + hp_bias + target_pressure_penalty + anti_core_bias + role_bias


func _get_role_target_bias(candidate: ModuleBase) -> float:
	match _role:
		ROLE_SPRINTER:
			if _board != null and _board.has_method("get_module_exposure_score"):
				var exposure: float = float(_board.call("get_module_exposure_score", candidate))
				return -exposure * 42.0
			return 0.0
		ROLE_TANK:
			if candidate.module_id == Constants.MODULE_REACTOR or candidate.module_id == Constants.MODULE_CORE:
				return -54.0
			return 0.0
		_:
			return 0.0


func _get_role_priority_bonus(module_id: String) -> int:
	match _role:
		ROLE_SPRINTER:
			if module_id == Constants.MODULE_HULL or module_id == Constants.MODULE_COLLECTOR:
				return 40
			if module_id == Constants.MODULE_TURRET:
				return -70
			return 0
		ROLE_TANK:
			if module_id == Constants.MODULE_REACTOR or module_id == Constants.MODULE_CORE:
				return 15
			return 0
		_:
			return 0
