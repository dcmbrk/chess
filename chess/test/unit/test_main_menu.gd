extends GutTest

const MAIN_MENU = preload("res://scenes/main-menu/main_menu.tscn")

var menu: Control


func before_each() -> void:
	menu = MAIN_MENU.instantiate()
	add_child_autofree(menu)


func after_each() -> void:
	Tooltip.hide_tooltip()


func test_has_every_button() -> void:
	assert_eq(menu.play_button.text, "Play!")
	for button: Button in [menu.settings_button, menu.collection_button, menu.credits_button, menu.quit_button]:
		assert_true(button.is_visible_in_tree(), button.name)


func test_play_starts_a_run() -> void:
	assert_true(menu.play_button.pressed.is_connected(menu._on_play_pressed))


func test_quit_quits() -> void:
	assert_true(menu.quit_button.pressed.is_connected(get_tree().quit))


func test_collection_is_disabled_with_a_hint() -> void:
	assert_true(menu.collection_button.disabled)
	menu.collection_button.mouse_entered.emit()
	assert_eq(Tooltip.body.text, "Coming soon")
	menu.collection_button.mouse_exited.emit()


func test_settings_button_opens_the_settings() -> void:
	assert_false(menu.settings_button.disabled)
	
	menu.settings_button.pressed.emit()
	
	assert_true(menu.settings_panel.visible)
	menu.settings_panel.close()


func test_credits_open_and_close() -> void:
	assert_false(menu.credits_panel.visible)
	
	menu.credits_button.pressed.emit()
	assert_true(menu.credits_panel.visible)
	
	menu.credits_close_button.pressed.emit()
	assert_false(menu.credits_panel.visible)


func test_credits_name_the_team() -> void:
	var team: Label = menu.get_node("CreditsPanel/CenterContainer/Panel/VBoxContainer/Team")
	
	assert_string_contains(team.text, "Lê Duy Tùng")
