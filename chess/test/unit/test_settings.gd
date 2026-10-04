extends GutTest

const TEST_PATH := "user://test_settings.cfg"
const SETTINGS_PANEL = preload("res://scenes/ui/settings/settings_panel.tscn")

var _saved_path: String


func before_all() -> void:
	_saved_path = Settings.path


func before_each() -> void:
	Settings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	Settings.reset_to_defaults()


func after_all() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	Settings.path = _saved_path
	Settings.load_settings()
	Settings.apply()
	PauseMenu.close()


# --- Settings ---

func test_defaults() -> void:
	assert_eq(Settings.volume, 80)
	assert_false(Settings.fullscreen)
	assert_true(Settings.move_hints)
	assert_false(Settings.fast_enemy)


func test_volume_is_clamped_and_snapped() -> void:
	Settings.set_volume(150)
	assert_eq(Settings.volume, 100)
	Settings.set_volume(-20)
	assert_eq(Settings.volume, 0)
	Settings.set_volume(44)
	assert_eq(Settings.volume, 40)


func test_volume_sets_the_master_bus() -> void:
	Settings.set_volume(50)
	assert_almost_eq(AudioServer.get_bus_volume_db(0), linear_to_db(0.5), 0.01)
	assert_false(AudioServer.is_bus_mute(0))
	
	Settings.set_volume(0)
	assert_true(AudioServer.is_bus_mute(0))


func test_settings_are_saved_and_loaded() -> void:
	Settings.set_volume(30)
	Settings.set_move_hints(false)
	Settings.set_fast_enemy(true)
	
	Settings.volume = 100
	Settings.move_hints = true
	Settings.fast_enemy = false
	Settings.load_settings()
	
	assert_eq(Settings.volume, 30)
	assert_false(Settings.move_hints)
	assert_true(Settings.fast_enemy)


func test_missing_file_keeps_current_values() -> void:
	Settings.volume = 70
	DirAccess.remove_absolute(TEST_PATH)
	
	Settings.load_settings()
	
	assert_eq(Settings.volume, 70)


func test_changes_emit_changed() -> void:
	watch_signals(Settings)
	
	Settings.set_fullscreen(true)
	
	assert_signal_emitted(Settings, "changed")


func test_fast_enemy_shortens_the_delay() -> void:
	assert_eq(Settings.get_enemy_delay(0.5), 0.5)
	
	Settings.set_fast_enemy(true)
	
	assert_almost_eq(Settings.get_enemy_delay(0.5), 0.2, 0.001)


# --- Gameplay effects ---

func test_move_hints_off_hides_hints() -> void:
	var arena := ArenaHelper.create_arena(self)
	var hints: TileMapLayer = arena.board.get_node("MoveHints")
	var black_pawn: Unit = arena.board.unit_grid.units[Vector2i(1, 1)]
	Settings.set_move_hints(false)
	
	arena.move_highlighter.show_moves(black_pawn)
	
	assert_eq(hints.get_used_cells().size(), 0)


# --- Panel ---

func _create_panel() -> SettingsPanel:
	var panel: SettingsPanel = add_child_autofree(SETTINGS_PANEL.instantiate())
	panel.open()
	return panel


func test_panel_shows_current_values() -> void:
	var panel := _create_panel()
	
	assert_true(panel.visible)
	assert_eq(panel.volume_label.text, "80%")
	assert_eq(panel.fullscreen_button.text, "Off")
	assert_eq(panel.move_hints_button.text, "On")
	assert_eq(panel.fast_enemy_button.text, "Off")


func test_panel_buttons_change_settings() -> void:
	var panel := _create_panel()
	
	panel.volume_up_button.pressed.emit()
	panel.move_hints_button.pressed.emit()
	panel.fast_enemy_button.pressed.emit()
	
	assert_eq(Settings.volume, 90)
	assert_eq(panel.volume_label.text, "90%")
	assert_false(Settings.move_hints)
	assert_eq(panel.move_hints_button.text, "Off")
	assert_true(Settings.fast_enemy)


func test_volume_buttons_stop_at_the_limits() -> void:
	Settings.set_volume(100)
	var panel := _create_panel()
	assert_true(panel.volume_up_button.disabled)
	
	Settings.set_volume(0)
	assert_true(panel.volume_down_button.disabled)


func test_close_hides_the_panel() -> void:
	var panel := _create_panel()
	watch_signals(panel)
	
	panel.close_button.pressed.emit()
	
	assert_false(panel.visible)
	assert_signal_emitted(panel, "closed")


func test_panel_works_while_paused() -> void:
	assert_eq(_create_panel().process_mode, Node.PROCESS_MODE_ALWAYS)


func test_pause_menu_opens_settings() -> void:
	PauseMenu.open()
	
	PauseMenu.settings_button.pressed.emit()
	
	assert_true(PauseMenu.settings_panel.visible)
	PauseMenu.close()
	assert_false(PauseMenu.settings_panel.visible, "closing the pause menu closes the settings too")
