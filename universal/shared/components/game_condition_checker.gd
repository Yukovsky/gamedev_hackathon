extends RefCounted
class_name GameConditionChecker
## Проверка условий победы и поражения.
## Статические методы для чистой проверки без side-effects.

const REACTORS_TO_WIN: int = 4


static func check_win(
	placed_modules: Array[ModuleBase],
	is_game_finished: bool
) -> Dictionary:
	## Возвращает { "won": bool, "reason": String }
	if is_game_finished:
		return { "won": false, "reason": "" }
	
	var reactor_count: int = 0
	for module in placed_modules:
		if not is_instance_valid(module):
			continue
		if module.module_id == Constants.MODULE_REACTOR:
			reactor_count += 1
	
	if reactor_count >= REACTORS_TO_WIN:
		return { "won": true, "reason": "reactors_4" }
	
	return { "won": false, "reason": "" }


static func check_lose_core_destroyed(
	core_module: ModuleBase,
	source: String
) -> Dictionary:
	## Возвращает { "lost": bool, "reason": String }
	if core_module == null or not is_instance_valid(core_module):
		var reason: String = "core_destroyed"
		if source == "raider":
			reason = "core_eaten_by_raiders"
		return { "lost": true, "reason": reason }
	
	return { "lost": false, "reason": "" }
