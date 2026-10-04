extends GutTest

const GRAVEYARD_PANEL = preload("res://scenes/ui/graveyard/graveyard_panel.tscn")
const WHITE_PAWN = preload("res://data/pieces/white_pawn.tres")
const WHITE_KNIGHT = preload("res://data/pieces/white_knight.tres")
const BLACK_PAWN = preload("res://data/pieces/black_pawn.tres")


func before_each() -> void:
	RunState.reset()


func after_all() -> void:
	RunState.reset()


# --- RunState ---

func test_run_starts_with_starting_pieces_and_empty_graveyard() -> void:
	assert_eq(RunState.pieces, RunState.STARTING_PIECES)
	assert_eq(RunState.graveyard.size(), 0)


func test_reset_does_not_share_the_starting_array() -> void:
	RunState.pieces.clear()
	RunState.reset()
	
	assert_eq(RunState.STARTING_PIECES.size(), 2)
	assert_eq(RunState.pieces.size(), 2)


func test_lose_piece_moves_it_to_graveyard() -> void:
	RunState.lose_piece(WHITE_KNIGHT)
	
	assert_eq(RunState.pieces, [WHITE_PAWN] as Array[UnitStats])
	assert_eq(RunState.graveyard, [WHITE_KNIGHT] as Array[UnitStats])


func test_graveyard_keeps_only_the_last_five() -> void:
	for i in 7:
		RunState.lose_piece(WHITE_PAWN if i < 6 else WHITE_KNIGHT)
	
	assert_eq(RunState.graveyard.size(), RunState.GRAVEYARD_SIZE)
	assert_eq(RunState.graveyard.back(), WHITE_KNIGHT, "newest piece is kept")


func test_revive_piece_returns_it_to_stock() -> void:
	RunState.lose_piece(WHITE_KNIGHT)
	
	assert_true(RunState.revive_piece(0))
	assert_has(RunState.pieces, WHITE_KNIGHT)
	assert_eq(RunState.graveyard.size(), 0)


func test_cannot_revive_with_full_stock() -> void:
	RunState.lose_piece(WHITE_KNIGHT)
	while RunState.pieces.size() < RunState.MAX_PIECES:
		RunState.pieces.append(WHITE_PAWN)
	
	assert_false(RunState.revive_piece(0))
	assert_eq(RunState.graveyard.size(), 1)


func test_cannot_revive_invalid_index() -> void:
	assert_false(RunState.revive_piece(0))
	assert_false(RunState.revive_piece(-1))


# --- Panel ---

func test_panel_shows_one_slot_per_graveyard_piece() -> void:
	RunState.lose_piece(WHITE_PAWN)
	RunState.lose_piece(WHITE_KNIGHT)
	var panel: GraveyardPanel = add_child_autofree(GRAVEYARD_PANEL.instantiate())
	
	panel.open()
	
	assert_true(panel.visible)
	assert_eq(panel.slots.get_child_count(), 2)
	assert_eq(panel.slots.get_child(0).text, "$%d" % RunState.REVIVE_PRICE)


func test_clicking_slot_revives_piece() -> void:
	RunState.lose_piece(WHITE_KNIGHT)
	var panel: GraveyardPanel = add_child_autofree(GRAVEYARD_PANEL.instantiate())
	panel.open()
	
	panel.slots.get_child(0).pressed.emit()
	
	assert_has(RunState.pieces, WHITE_KNIGHT)
	assert_eq(panel.slots.get_child_count(), 0)


func test_next_closes_panel() -> void:
	var panel: GraveyardPanel = add_child_autofree(GRAVEYARD_PANEL.instantiate())
	panel.open()
	watch_signals(panel)
	
	panel.next_button.pressed.emit()
	
	assert_false(panel.visible)
	assert_signal_emitted(panel, "closed")


# --- Arena ---

func test_arena_spawns_run_pieces_on_the_bench() -> void:
	var arena := ArenaHelper.create_arena(self)
	var bench_units: Array[Unit] = (arena.get_node("Bench") as PlayArea).unit_grid.get_all_units()
	
	assert_eq(bench_units.size(), RunState.pieces.size())
	assert_eq(arena.board.unit_grid.get_all_units().size(), 3, "only the black pawns")
	assert_eq(arena.prep_panel.pieces_label.text, "Pieces 0/3")
	assert_true(arena.prep_panel.go_button.disabled)


func test_captured_player_piece_goes_to_graveyard() -> void:
	var arena := ArenaHelper.create_arena(self)
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	var knight := ArenaHelper.move_to_board(arena, Vector2i(0, 1), Vector2i(2, 2))
	arena.preparation.start_battle()
	arena.turn_manager.end_turn(arena.board.unit_grid.to_board_state())
	var black_pawn: Unit = arena.board.unit_grid.units[Vector2i(1, 1)]
	
	arena.unit_mover.perform_board_move(black_pawn, Vector2i(1, 1), Vector2i(2, 2))
	
	assert_true(knight.is_queued_for_deletion())
	assert_eq(RunState.graveyard, [WHITE_KNIGHT] as Array[UnitStats])
	assert_eq(RunState.pieces, [WHITE_PAWN] as Array[UnitStats])
	assert_eq(arena.captured_enemies, 0)


func test_graveyard_opens_after_results_when_not_empty() -> void:
	var arena := ArenaHelper.create_arena(self)
	RunState.lose_piece(WHITE_KNIGHT)
	arena.battle_result.show_result(GameRules.Outcome.WIN, BattleRewards.calculate(GameRules.Outcome.WIN, 0, 0), 0)
	
	arena.battle_result.continue_button.pressed.emit()
	
	assert_true(arena.graveyard_panel.visible)
