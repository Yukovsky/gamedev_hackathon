extends "res://addons/gut/test.gd"

var save_manager
var resource_manager
var upgrade_manager

const TEST_SAVE_PATH = "user://test_save.json"

func before_all():
	save_manager = SaveManager
	resource_manager = ResourceManager
	upgrade_manager = UpgradeManager
	# Подменяем путь сохранения на тестовый
	save_manager.set("SAVE_PATH", TEST_SAVE_PATH)

func before_each():
	# Очищаем состояние перед тестом
	resource_manager.reset_run_state()
	upgrade_manager.reset_run_state()
	save_manager.tutorial_flags = {}
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)

func after_all():
	# Возвращаем оригинальный путь (хотя в headless это не критично)
	save_manager.set("SAVE_PATH", "user://universal_save.json")
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)

func test_save_and_load_resources():
	resource_manager.metal = 150
	resource_manager.max_metal = 500
	
	save_manager.save_game()
	
	# Сбрасываем значения, чтобы проверить загрузку
	resource_manager.metal = 0
	resource_manager.max_metal = 0
	
	save_manager.load_game()
	
	assert_eq(resource_manager.metal, 150, "Металл должен восстановиться")
	assert_eq(resource_manager.max_metal, 500, "Лимит металла должен восстановиться")

func test_save_and_load_upgrades():
	var upgrade_id = Constants.UPGRADE_CORE_ID
	upgrade_manager.set_upgrade_levels({upgrade_id: 3})
	
	save_manager.save_game()
	
	upgrade_manager.reset_run_state()
	assert_eq(upgrade_manager.get_upgrade_level(upgrade_id), 0)
	
	save_manager.load_game()
	assert_eq(upgrade_manager.get_upgrade_level(upgrade_id), 3, "Уровень апгрейда должен восстановиться")

func test_tutorial_flags():
	var flag = "test_tutorial_id"
	assert_false(save_manager.is_tutorial_shown(flag))
	
	save_manager.mark_tutorial_shown(flag)
	assert_true(save_manager.is_tutorial_shown(flag), "Флаг должен установиться")
	
	# Проверяем, что сохранилось в файл
	save_manager.tutorial_flags = {}
	save_manager.load_game()
	assert_true(save_manager.is_tutorial_shown(flag), "Флаг должен восстановиться из файла")

func test_save_file_creation():
	assert_false(FileAccess.file_exists(TEST_SAVE_PATH))
	save_manager.save_game()
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH), "Файл сохранения должен быть создан на диске")
