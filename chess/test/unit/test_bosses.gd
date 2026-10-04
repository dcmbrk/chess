extends GutTest

const HUD = preload("res://scenes/ui/hud/hud.tscn")
const MAGNUS = preload("res://data/bosses/magnus_the_swift.tres")
const HIKARU = preload("res://data/bosses/hikaru_the_banished.tres")
const TAL = preload("res://data/bosses/tal_the_cursed.tres")
const KEV = preload("res://data/bosses/kev_borclick.tres")
const JAWBY = preload("res://data/bosses/jawby_fisher.tres")
const Type := UnitStats.Type
const Team := UnitStats.Team


func before_each() -> void:
	RunState.reset()
	Tooltip.hide_tooltip()


func after_all() -> void:
	RunState.reset()


func _arena_with_boss(boss: BossData) -> Arena:
	RunState.reset()
	var arena: Arena = preload("res://scenes/arena/arena.tscn").instantiate()
	arena.encounter = ArenaHelper.three_pawns()
	arena.boss = boss
	add_child_autofree(arena)
	return arena


func _enemy_units(arena: Arena) -> Array[Unit]:
	var enemies: Array[Unit] = []
	for unit in arena.board.unit_grid.get_all_units():
		if unit.stats.team == Team.BLACK:
			enemies.append(unit)
	return enemies


# --- Board rules: CURSED and STASIS ---

func test_cursed_tile_blocks_only_its_team() -> void:
	var board := PieceFactory.board_with({Vector2i(2, 2): PieceFactory.make(Type.ROOK, Team.WHITE)})
	board.forbidden_tiles[Vector2i(2, 1)] = Team.WHITE
	
	var moves := MoveRules.get_legal_moves(board, Vector2i(2, 2))
	
	assert_does_not_have(moves, Vector2i(2, 1))
	assert_does_not_have(moves, Vector2i(2, 0), "can't slide through a cursed tile")
	assert_has(moves, Vector2i(2, 3))
	
	board.set_piece(Vector2i(2, 2), PieceFactory.make(Type.ROOK, Team.BLACK))
	assert_has(MoveRules.get_legal_moves(board, Vector2i(2, 2)), Vector2i(2, 1), "black ignores white's curse")


func test_cursed_tile_blocks_pawn_moves_and_captures() -> void:
	var board := PieceFactory.board_with({
		Vector2i(2, 2): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(1, 1): PieceFactory.make(Type.PAWN, Team.BLACK),
	})
	board.forbidden_tiles[Vector2i(2, 1)] = Team.WHITE
	board.forbidden_tiles[Vector2i(1, 1)] = Team.WHITE
	
	assert_eq(MoveRules.get_legal_moves(board, Vector2i(2, 2)), [] as Array[Vector2i])


func test_frozen_piece_cannot_move() -> void:
	var board := PieceFactory.board_with({Vector2i(2, 2): PieceFactory.make(Type.QUEEN, Team.BLACK)})
	board.frozen_tiles[Vector2i(2, 2)] = true
	
	assert_eq(MoveRules.get_legal_moves(board, Vector2i(2, 2)), [] as Array[Vector2i])


func test_frozen_piece_cannot_be_captured() -> void:
	var board := PieceFactory.board_with({
		Vector2i(2, 4): PieceFactory.make(Type.ROOK, Team.WHITE),
		Vector2i(2, 2): PieceFactory.make(Type.PAWN, Team.BLACK),
	})
	board.frozen_tiles[Vector2i(2, 2)] = true
	
	var moves := MoveRules.get_legal_moves(board, Vector2i(2, 4))
	
	assert_does_not_have(moves, Vector2i(2, 2))
	assert_does_not_have(moves, Vector2i(2, 1), "the frozen piece still blocks")
	assert_has(moves, Vector2i(2, 3))


func test_board_state_copies_effects_from_grid() -> void:
	var grid := UnitGrid.new()
	grid.size = Vector2i(5, 5)
	add_child_autofree(grid)
	grid.forbidden_tiles[Vector2i(1, 1)] = Team.WHITE
	grid.frozen_tiles[Vector2i(2, 2)] = true
	
	var board := grid.to_board_state()
	
	assert_true(board.is_forbidden(Vector2i(1, 1), Team.WHITE))
	assert_false(board.is_forbidden(Vector2i(1, 1), Team.BLACK))
	assert_true(board.is_frozen(Vector2i(2, 2)))


# --- RunState ---

func test_every_boss_is_complete() -> void:
	assert_eq(RunState.BOSS_POOL.size(), RunState.STAGE_COUNT)
	for boss in RunState.BOSS_POOL:
		assert_ne(boss.display_name, "", boss.resource_path)
		assert_ne(boss.description, "", boss.resource_path)


func test_run_starts_with_a_boss() -> void:
	assert_not_null(RunState.boss)
	assert_has(RunState.BOSS_POOL, RunState.boss)


func test_each_stage_has_a_different_boss() -> void:
	var seen := [RunState.boss]
	for stage in range(2, RunState.STAGE_COUNT + 1):
		for game in RunState.GAMES_PER_STAGE:
			RunState.advance()
		assert_does_not_have(seen, RunState.boss, "stage %d" % stage)
		seen.append(RunState.boss)


func test_boss_stays_the_same_during_a_stage() -> void:
	var boss := RunState.boss
	for game in RunState.GAMES_PER_STAGE - 1:
		RunState.advance()
	
	assert_eq(RunState.boss, boss)


func test_arena_uses_the_run_boss_only_on_boss_games() -> void:
	var normal := ArenaHelper.create_arena(self)
	assert_null(normal.boss)
	normal.free()
	
	RunState.reset()
	for game in RunState.GAMES_PER_STAGE - 1:
		RunState.advance()
	RunState.boss = MAGNUS
	var boss_arena: Arena = preload("res://scenes/arena/arena.tscn").instantiate()
	boss_arena.encounter = ArenaHelper.three_pawns()
	add_child_autofree(boss_arena)
	
	assert_eq(boss_arena.boss, MAGNUS)


# --- Bosses ---

func test_magnus_moves_first() -> void:
	var arena := _arena_with_boss(MAGNUS)
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	
	arena.preparation.start_battle()
	
	assert_eq(arena.turn_manager.current_team, Team.BLACK)


func test_hikaru_bans_the_stock_during_battle() -> void:
	var arena := _arena_with_boss(HIKARU)
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	var knight: Unit = arena.get_node("Bench").unit_grid.units[Vector2i(0, 1)]
	arena.preparation.start_battle()
	
	assert_false(arena.unit_mover.allow_stock_in_battle)
	assert_false(arena.unit_mover.perform_deploy(knight, Vector2i(2, 4)))


func test_tal_curses_empty_tiles() -> void:
	var arena := _arena_with_boss(TAL)
	var grid := arena.board.unit_grid
	
	assert_eq(grid.forbidden_tiles.size(), 5)
	for tile in grid.forbidden_tiles:
		assert_false(grid.is_tile_occupied(tile), "cursed tile %s was empty" % tile)
		assert_eq(grid.forbidden_tiles[tile], Team.WHITE)


func test_cannot_place_a_piece_on_a_cursed_tile() -> void:
	var arena := _arena_with_boss(TAL)
	var knight: Unit = arena.get_node("Bench").unit_grid.units[Vector2i(0, 1)]
	var grid := arena.board.unit_grid
	grid.forbidden_tiles.clear()
	grid.forbidden_tiles[Vector2i(2, 4)] = Team.WHITE
	
	assert_false(arena.preparation.can_drop(knight, false, true, Vector2i(2, 4), null))
	assert_true(arena.preparation.can_drop(knight, false, true, Vector2i(3, 4), null))


func test_kev_freezes_two_enemies_then_wears_off() -> void:
	var arena := _arena_with_boss(KEV)
	var grid := arena.board.unit_grid
	assert_eq(grid.frozen_tiles.size(), 2)
	for tile in grid.frozen_tiles:
		assert_eq((grid.units[tile] as Unit).modulate, StasisBoss.STASIS_TINT)
	var frozen_unit: Unit = grid.units[grid.frozen_tiles.keys()[0]]
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	arena.preparation.start_battle()
	
	var board := grid.to_board_state()
	for i in KEV.duration * 2:
		arena.turn_manager.end_turn(board)
	assert_eq(grid.frozen_tiles.size(), 2, "still frozen after %d boss turns" % KEV.duration)
	
	arena.turn_manager.end_turn(board)
	
	assert_eq(grid.frozen_tiles.size(), 0)
	assert_eq(frozen_unit.modulate, Color.WHITE)


func test_jawby_destroys_a_stock_piece_when_capturing() -> void:
	var arena := _arena_with_boss(JAWBY)
	var pawn := ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(2, 2))
	var knight: Unit = arena.get_node("Bench").unit_grid.units[Vector2i(0, 1)]
	arena.preparation.start_battle()
	arena.turn_manager.end_turn(arena.board.unit_grid.to_board_state())
	var black_pawn: Unit = arena.board.unit_grid.units[Vector2i(1, 1)]
	
	arena.unit_mover.perform_board_move(black_pawn, Vector2i(1, 1), Vector2i(2, 2))
	
	assert_true(pawn.is_queued_for_deletion(), "captured")
	assert_true(knight.is_queued_for_deletion(), "destroyed from the stock")
	assert_eq(RunState.pieces.size(), 0)
	assert_eq(RunState.graveyard, [preload("res://data/pieces/white_pawn.tres")] as Array[UnitStats], "only the captured piece")


func test_jawby_ignores_player_captures() -> void:
	var arena := _arena_with_boss(JAWBY)
	var pawn := ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(2, 2))
	var knight: Unit = arena.get_node("Bench").unit_grid.units[Vector2i(0, 1)]
	arena.preparation.start_battle()
	
	arena.unit_mover.perform_board_move(pawn, Vector2i(2, 2), Vector2i(1, 1))
	
	assert_false(knight.is_queued_for_deletion())


# --- Boss label ---

func test_boss_label_is_hidden_outside_boss_battles() -> void:
	var hud: CanvasLayer = add_child_autofree(HUD.instantiate())
	
	assert_false(hud.get_node("BossLabel").visible)


func test_normal_battle_hides_the_boss_label() -> void:
	var arena := ArenaHelper.create_arena(self)
	
	assert_false(arena.boss_label.visible)


func test_boss_battle_shows_the_boss_label() -> void:
	var arena := _arena_with_boss(TAL)
	
	assert_true(arena.boss_label.visible)
	assert_eq(arena.boss_label.text, "BOSS: Tal")
	
	arena.boss_label.mouse_entered.emit()
	assert_eq(Tooltip.title.text, "Tal the Cursed")
	assert_eq(Tooltip.body.text, TAL.description)
	arena.boss_label.mouse_exited.emit()
