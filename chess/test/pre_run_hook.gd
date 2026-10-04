## Runs before the tests: keeps them away from the player's real save and settings.
extends GutHookScript

const TEST_PROGRESS_PATH := "user://test_save.json"
const TEST_SETTINGS_PATH := "user://test_settings.cfg"


func run() -> void:
	var root: Window = gut.get_tree().root
	var progress: Node = root.get_node("Progress")
	progress.path = TEST_PROGRESS_PATH
	progress.clear()
	
	var settings: Node = root.get_node("Settings")
	settings.path = TEST_SETTINGS_PATH
	settings.reset_to_defaults()
