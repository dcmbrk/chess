extends GutTest

const COLLECTION = preload("res://scenes/collection/collection_screen.tscn")
const PIECE_WHEELS = preload("res://scenes/piece_wheels/piece_wheels.tscn")
const WHITE_KNIGHT = preload("res://data/pieces/white_knight.tres")
const WHITE_QUEEN = preload("res://data/pieces/white_queen.tres")
const ROYAL_TAX = preload("res://data/gambits/royal_tax.tres")
const TAL = preload("res://data/bosses/tal_the_cursed.tres")


func before_each() -> void:
	Progress.clear()
	RunState.reset()


func after_each() -> void:
	Tooltip.hide_tooltip()


func after_all() -> void:
	Progress.clear()
	RunState.reset()


# --- Safety ---

func test_tests_never_touch_the_real_save() -> void:
	assert_ne(Progress.path, Progress.DEFAULT_PATH, "the GUT pre-run hook must redirect the save")
	assert_ne(Settings.path, Settings.DEFAULT_PATH)


# --- Progress ---

func test_discover() -> void:
	assert_false(Progress.is_discovered(WHITE_KNIGHT))
	watch_signals(Progress)
	
	Progress.discover(WHITE_KNIGHT)
	Progress.discover(WHITE_KNIGHT)
	
	assert_true(Progress.is_discovered(WHITE_KNIGHT))
	assert_eq(Progress.pieces.size(), 1, "no duplicates")
	assert_signal_emit_count(Progress, "changed", 1)


func test_each_kind_has_its_own_list() -> void:
	Progress.discover_all([WHITE_KNIGHT, ROYAL_TAX, TAL])
	
	assert_eq(Progress.pieces, [WHITE_KNIGHT.resource_path] as Array[String])
	assert_eq(Progress.gambits, [ROYAL_TAX.resource_path] as Array[String])
	assert_eq(Progress.bosses, [TAL.resource_path] as Array[String])


func test_stats() -> void:
	Progress.record_run_started()
	Progress.record_run_started()
	Progress.record_run_won()
	Progress.record_stage(3)
	Progress.record_stage(2)
	
	assert_eq(Progress.runs_started, 2)
	assert_eq(Progress.runs_won, 1)
	assert_eq(Progress.best_stage, 3, "only goes up")


func test_progress_is_saved_and_loaded() -> void:
	Progress.discover_all([WHITE_KNIGHT, ROYAL_TAX])
	Progress.record_stage(4)
	
	Progress.pieces.clear()
	Progress.gambits.clear()
	Progress.best_stage = 0
	Progress.load_progress()
	
	assert_true(Progress.is_discovered(WHITE_KNIGHT))
	assert_true(Progress.is_discovered(ROYAL_TAX))
	assert_eq(Progress.best_stage, 4)


func test_broken_save_is_ignored() -> void:
	Progress.discover(WHITE_KNIGHT)
	var file := FileAccess.open(Progress.path, FileAccess.WRITE)
	file.store_string("not json")
	file.close()
	
	Progress.load_progress()
	
	assert_true(Progress.is_discovered(WHITE_KNIGHT), "keeps what it had")
	assert_engine_error_count(0)


# --- Where things get discovered ---

func test_piece_wheels_count_a_run_and_discover_the_results() -> void:
	var wheels: PieceWheels = PIECE_WHEELS.instantiate()
	wheels.next_scene = ""
	wheels.stop_delay = 0.0
	add_child_autofree(wheels)
	assert_eq(Progress.runs_started, 1)
	assert_eq(Progress.best_stage, 1)
	
	wheels.action_button.pressed.emit()
	await wait_process_frames(2)
	wheels.action_button.pressed.emit()
	
	for piece in wheels.results:
		assert_true(Progress.is_discovered(piece))


func test_buying_discovers() -> void:
	RunState.money = 100
	RunState.item_offers = [WHITE_QUEEN, ROYAL_TAX, null]
	
	RunState.buy_item(0)
	RunState.buy_item(1)
	
	assert_true(Progress.is_discovered(WHITE_QUEEN))
	assert_true(Progress.is_discovered(ROYAL_TAX))


func test_fighting_a_boss_discovers_it() -> void:
	var arena: Arena = preload("res://scenes/arena/arena.tscn").instantiate()
	arena.encounter = ArenaHelper.three_pawns()
	arena.boss = TAL
	add_child_autofree(arena)
	
	assert_true(Progress.is_discovered(TAL))


# --- Collection screen ---

func _create_screen() -> CollectionScreen:
	var screen: CollectionScreen = COLLECTION.instantiate()
	screen.back_scene = ""
	add_child_autofree(screen)
	return screen


func test_shows_every_piece_with_a_counter() -> void:
	Progress.discover(WHITE_KNIGHT)
	var screen := _create_screen()
	
	assert_eq(screen.entries.get_child_count(), RunState.SHOP_POOL.size())
	assert_eq(screen.counter_label.text, "Pieces 1/%d" % RunState.SHOP_POOL.size())


func test_undiscovered_entries_are_hidden() -> void:
	var screen := _create_screen()
	var entry: Button = screen.entries.get_child(0)
	
	assert_eq(entry.text, "?")
	assert_null(entry.icon)
	entry.mouse_entered.emit()
	assert_eq(Tooltip.title.text, "???")


func test_discovered_piece_shows_its_icon_and_tooltip() -> void:
	Progress.discover(WHITE_KNIGHT)
	var screen := _create_screen()
	var index := RunState.SHOP_POOL.find(WHITE_KNIGHT)
	var entry: Button = screen.entries.get_child(index)
	
	assert_not_null(entry.icon)
	entry.mouse_entered.emit()
	assert_eq(Tooltip.title.text, "Knight")


func test_tabs_switch_lists() -> void:
	Progress.discover_all([ROYAL_TAX, TAL])
	var screen := _create_screen()
	
	screen.tab_buttons[CollectionScreen.Tab.GAMBITS].pressed.emit()
	assert_eq(screen.entries.get_child_count(), RunState.GAMBIT_POOL.size())
	assert_eq(screen.counter_label.text, "Gambits 1/%d" % RunState.GAMBIT_POOL.size())
	assert_true(screen.tab_buttons[CollectionScreen.Tab.GAMBITS].disabled, "selected tab")
	
	screen.tab_buttons[CollectionScreen.Tab.BOSSES].pressed.emit()
	assert_eq(screen.counter_label.text, "Bosses 1/%d" % RunState.BOSS_POOL.size())
	var tal_entry: Button = screen.entries.get_child(RunState.BOSS_POOL.find(TAL))
	assert_eq(tal_entry.text, "Tal")


func test_stats_line() -> void:
	Progress.record_run_started()
	Progress.record_stage(2)
	
	var screen := _create_screen()
	
	assert_eq(screen.stats_label.text, "Runs 1 · Wins 0 · Best stage 2")
