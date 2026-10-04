extends GutTest

const PIECE_WHEELS = preload("res://scenes/piece_wheels/piece_wheels.tscn")


func before_each() -> void:
	PauseMenu.main_menu_scene = ""
	PauseMenu.run_start_scene = ""


func after_each() -> void:
	PauseMenu.close()
	PauseMenu.cancel_restart()


func after_all() -> void:
	PauseMenu.main_menu_scene = PauseMenu.MAIN_MENU_SCENE
	PauseMenu.run_start_scene = PauseMenu.RUN_START_SCENE
	RunState.reset()


# --- Seed ---

func test_reset_with_a_seed() -> void:
	RunState.reset(123)
	
	assert_eq(RunState.run_seed, 123)


func test_reset_without_a_seed_picks_a_new_one() -> void:
	RunState.reset()
	var first := RunState.run_seed
	RunState.reset()
	
	assert_ne(RunState.run_seed, first)


func _snapshot_run(seed_value: int) -> Array:
	RunState.reset(seed_value)
	var bosses := [RunState.boss]
	var encounter := RunState.pick_encounter()
	RunState.restock_shop()
	var offers := RunState.token_offers.duplicate()
	var gambit_offers := RunState.item_offers.duplicate()
	for i in RunState.GAMES_PER_STAGE:
		RunState.advance()
	bosses.append(RunState.boss)
	return [bosses, encounter, offers, gambit_offers]


func test_same_seed_gives_the_same_run() -> void:
	assert_eq(_snapshot_run(42), _snapshot_run(42))


func test_different_seeds_give_different_runs() -> void:
	var runs := {}
	for seed_value in 10:
		runs[str(_snapshot_run(seed_value))] = true
	
	assert_gt(runs.size(), 1)


func test_piece_wheels_follow_the_seed() -> void:
	RunState.reset(7)
	var first: PieceWheels = PIECE_WHEELS.instantiate()
	first.next_scene = ""
	add_child_autofree(first)
	RunState.reset(7)
	var second: PieceWheels = PIECE_WHEELS.instantiate()
	second.next_scene = ""
	add_child_autofree(second)
	
	assert_eq(first.results, second.results)


# --- Pause menu ---

func test_run_scenes_are_tagged() -> void:
	for path in ["res://scenes/arena/arena.tscn", "res://scenes/shop/shop_screen.tscn", "res://scenes/piece_wheels/piece_wheels.tscn"]:
		var state := (load(path) as PackedScene).get_state()
		assert_has(state.get_node_groups(0), &"run_scenes", path)


func test_main_menu_is_not_a_run_scene() -> void:
	var state := (load("res://scenes/main-menu/main_menu.tscn") as PackedScene).get_state()
	
	assert_does_not_have(state.get_node_groups(0), &"run_scenes")


func test_inactive_outside_run_scenes() -> void:
	assert_false(PauseMenu.is_active(), "the test runner is not a run scene")


func test_open_pauses_and_shows_the_seed() -> void:
	RunState.reset(787690496)
	
	PauseMenu.open()
	
	assert_true(PauseMenu.is_open())
	assert_true(get_tree().paused)
	assert_eq(PauseMenu.seed_label.text, "Seed 787690496")


func test_resume_unpauses() -> void:
	PauseMenu.open()
	
	PauseMenu.resume_button.pressed.emit()
	
	assert_false(PauseMenu.is_open())
	assert_false(get_tree().paused)


func test_main_menu_button_unpauses() -> void:
	PauseMenu.open()
	
	PauseMenu.main_menu_button.pressed.emit()
	
	assert_false(get_tree().paused)


func test_pause_menu_keeps_running_while_paused() -> void:
	assert_eq(PauseMenu.process_mode, Node.PROCESS_MODE_ALWAYS)


# --- Restart ---

func test_holding_restart_shows_progress_then_restarts() -> void:
	RunState.reset(1)
	RunState.add_money(9)
	
	PauseMenu.hold_restart(PauseMenu.restart_hold_time / 2)
	assert_true(PauseMenu.restart_label.visible)
	assert_eq(RunState.money, 9, "not restarted yet")
	
	PauseMenu.hold_restart(PauseMenu.restart_hold_time / 2)
	
	assert_eq(RunState.money, RunState.STARTING_MONEY)
	assert_ne(RunState.run_seed, 1, "a new run gets a new seed")
	assert_false(PauseMenu.restart_label.visible)


func test_releasing_r_cancels_the_restart() -> void:
	RunState.add_money(9)
	PauseMenu.hold_restart(PauseMenu.restart_hold_time / 2)
	
	PauseMenu.cancel_restart()
	PauseMenu.hold_restart(PauseMenu.restart_hold_time / 2)
	
	assert_eq(RunState.money, 9)


func test_restart_unpauses() -> void:
	PauseMenu.open()
	
	PauseMenu.restart_run()
	
	assert_false(get_tree().paused)
	assert_false(PauseMenu.is_open())
