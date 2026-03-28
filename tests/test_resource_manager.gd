@tool
extends EditorScript

# Скрипт для запуска тестов ResourceManager в контексте редактора.
# Чтобы запустить: File -> Run (в окне кода Godot) или через mcp_execute_editor_script

var resource_manager: Node

func _run():
	print("--- Running Tests for ResourceManager ---")
	
	# Создаем изолированный экземпляр для тестов, чтобы не портить живой ResourceManager
	resource_manager = load("res://core/resource_manager.gd").new()
	
	test_initial_state()
	test_metal_collection()
	test_metal_limit()
	test_spend_metal()
	
	print("--- All Tests Completed Successfully ---")
	
	resource_manager.free()

func assert_true(condition: bool, message: String):
	if not condition:
		push_error("FAILED: " + message)
		breakpoint
	else:
		print("PASSED: " + message)

func test_initial_state():
	assert_true(resource_manager.metal == 0, "Initial metal should be 0")
	assert_true(resource_manager.max_metal == 10, "Initial max_metal should be 10")

func test_metal_collection():
	resource_manager.metal = 0
	resource_manager._on_metal_collected(5)
	assert_true(resource_manager.metal == 5, "Metal should be 5 after collecting 5")

func test_metal_limit():
	resource_manager.max_metal = 10
	resource_manager.metal = 0
	resource_manager._on_metal_collected(15)
	assert_true(resource_manager.metal == 10, "Metal should be clamped to max_metal (10)")

func test_spend_metal():
	resource_manager.metal = 10
	var success = resource_manager.spend_metal(4)
	assert_true(success == true, "Should be able to spend 4 metal if we have 10")
	assert_true(resource_manager.metal == 6, "Metal should be 6 after spending 4")
	
	var fail = resource_manager.spend_metal(10)
	assert_true(fail == false, "Should not be able to spend 10 metal if we have 6")
	assert_true(resource_manager.metal == 6, "Metal should remain 6 after failed spend")
