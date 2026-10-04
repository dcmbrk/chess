extends GutTest

const PROTECTION = preload("res://data/tiles/protection.tres")
const BENEDICTION = preload("res://data/tiles/benediction.tres")
const HUNTER = preload("res://data/tiles/hunter.tres")
const PHANTOM = preload("res://data/tiles/phantom.tres")
const WHITE_PAWN = preload("res://data/pieces/white_pawn.tres")
const WHITE_ROOK = preload("res://data/pieces/white_rook.tres")
const BLACK_PAWN = preload("res://data/pieces/black_pawn.tres")
const BLACK_ROOK = preload("res://data/pieces/black_rook.tres")
const COLLECTION = preload("res://scenes/collection/collection_screen.tscn")
const Team := UnitStats.Team
const Type := UnitStats.Type


func before_each() -> void:
	RunState.reset()
	Tooltip.hide_tooltip()


func after_all() -> void:
	RunState.reset()


func _board(pieces: Dictionary, tiles: Dictionary) -> BoardState:
	var board := PieceFactory.board_with(pieces)
	for tile: Vector2i in tiles:
		(tiles[tile] as SpecialTileData).apply_to(board, tile, Team.WHITE)
	return board


# --- Data ---

func test_every_tile_is_complete() -> void:
	var effects := {}
	for tile in RunState.TILE_POOL:
		assert_ne(tile.display_name, "", tile.resource_path)
		assert_ne(tile.description, "", tile.resource_path)
		assert_gt(tile.price, 0)
		assert_eq(tile.texture.get_size(), Vector2(64, 64), tile.resource_path)
		effects[tile.effect] = true
	assert_eq(effects.size(), SpecialTileData.Effect.size(), "one tile per effect")


# --- Rules ---

func test_protection_saves_the_player_piece() -> void:
	var board := _board({
		Vector2i(2, 3): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(2, 0): PieceFactory.make(Type.ROOK, Team.BLACK),
	}, {Vector2i(2, 3): PROTECTION})
	
	assert_does_not_have(MoveRules.get_legal_moves(board, Vector2i(2, 0)), Vector2i(2, 3))


func test_protection_does_not_save_an_enemy_standing_on_it() -> void:
	var board := _board({
		Vector2i(2, 3): PieceFactory.make(Type.PAWN, Team.BLACK),
		Vector2i(2, 4): PieceFactory.make(Type.ROOK, Team.WHITE),
	}, {Vector2i(2, 3): PROTECTION})
	
	assert_has(MoveRules.get_legal_moves(board, Vector2i(2, 4)), Vector2i(2, 3))


func test_phantom_is_a_wall_for_the_enemy_only() -> void:
	var board := _board({
		Vector2i(2, 0): PieceFactory.make(Type.ROOK, Team.BLACK),
		Vector2i(0, 3): PieceFactory.make(Type.ROOK, Team.WHITE),
	}, {Vector2i(2, 3): PHANTOM})
	
	var black_moves := MoveRules.get_legal_moves(board, Vector2i(2, 0))
	assert_does_not_have(black_moves, Vector2i(2, 3))
	assert_does_not_have(black_moves, Vector2i(2, 4), "can't slide through")
	assert_has(MoveRules.get_legal_moves(board, Vector2i(0, 3)), Vector2i(2, 3), "white walks on it")


func test_hunter_destroys_an_enemy_moving_onto_it() -> void:
	var board := _board({Vector2i(2, 2): PieceFactory.make(Type.PAWN, Team.BLACK)}, {Vector2i(2, 3): HUNTER})
	
	board.move_piece(Vector2i(2, 2), Vector2i(2, 3))
	
	assert_true(board.is_empty(Vector2i(2, 3)))


func test_hunter_spares_the_player_pieces() -> void:
	var rook := PieceFactory.make(Type.ROOK, Team.WHITE)
	var board := _board({Vector2i(2, 4): rook}, {Vector2i(2, 3): HUNTER})
	
	board.move_piece(Vector2i(2, 4), Vector2i(2, 3))
	
	assert_eq(board.get_piece(Vector2i(2, 3)), rook)


func test_ai_avoids_the_hunter_trap() -> void:
	# The black rook's only capture lands on the trap: it would lose itself for a pawn.
	var board := _board({
		Vector2i(2, 0): PieceFactory.make(Type.ROOK, Team.BLACK),
		Vector2i(2, 3): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(4, 4): PieceFactory.make(Type.KNIGHT, Team.WHITE),
	}, {Vector2i(2, 3): HUNTER})
	
	var move := ChessAI.choose_move(board, Team.BLACK, 1)
	
	assert_ne(move.to, Vector2i(2, 3))
	assert_false(board.is_empty(Vector2i(2, 0)), "the search left the board as it was")


# --- In the arena ---

func _arena_with_tiles(placed: Dictionary) -> Arena:
	var arena := ArenaHelper.create_arena(self)
	for tile: Vector2i in placed:
		arena.board.unit_grid.special_tiles[tile] = placed[tile]
	return arena


func test_enemy_moving_onto_a_hunter_tile_is_destroyed() -> void:
	var arena := _arena_with_tiles({Vector2i(1, 2): HUNTER})
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(4, 4))
	arena.preparation.start_battle()
	arena.turn_manager.end_turn(arena.board.unit_grid.to_board_state())
	var black_pawn: Unit = arena.board.unit_grid.units[Vector2i(1, 1)]
	watch_signals(arena.unit_mover)
	
	assert_true(arena.unit_mover.perform_board_move(black_pawn, Vector2i(1, 1), Vector2i(1, 2)))
	
	assert_true(black_pawn.is_queued_for_deletion())
	assert_null(arena.board.unit_grid.units[Vector2i(1, 2)])
	assert_signal_emitted_with_parameters(arena.unit_mover, "unit_captured", [black_pawn, null])
	assert_eq(arena.captured_enemies, 1, "counts for the rewards")
	assert_eq(arena.turn_manager.current_team, Team.WHITE)


func test_benediction_pays_the_player() -> void:
	var arena := _arena_with_tiles({Vector2i(4, 3): BENEDICTION})
	var pawn := ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(4, 4))
	arena.preparation.start_battle()
	
	arena.unit_mover.perform_board_move(pawn, Vector2i(4, 4), Vector2i(4, 3))
	
	assert_eq(RunState.money, SpecialTileData.BENEDICTION_MONEY)


func test_benediction_also_pays_for_a_stock_piece_put_on_it() -> void:
	var arena := _arena_with_tiles({Vector2i(3, 4): BENEDICTION})
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	var knight: Unit = arena.get_node("Bench").unit_grid.units[Vector2i(0, 1)]
	arena.preparation.start_battle()
	
	assert_true(arena.unit_mover.perform_deploy(knight, Vector2i(3, 4)))
	
	assert_eq(RunState.money, SpecialTileData.BENEDICTION_MONEY)


func test_placed_tiles_come_back_every_battle() -> void:
	RunState.placed_tiles[Vector2i(2, 4)] = PROTECTION
	var arena: Arena = preload("res://scenes/arena/arena.tscn").instantiate()
	arena.encounter = ArenaHelper.three_pawns()
	add_child_autofree(arena)
	
	assert_eq(arena.board.unit_grid.special_tiles, {Vector2i(2, 4): PROTECTION} as Dictionary[Vector2i, SpecialTileData])


func test_tal_never_curses_a_special_tile() -> void:
	RunState.reset()
	var arena: Arena = preload("res://scenes/arena/arena.tscn").instantiate()
	arena.encounter = ArenaHelper.three_pawns()
	arena.boss = preload("res://data/bosses/tal_the_cursed.tres")
	# Fill every empty tile but a few with special tiles.
	for x in 5:
		for y in [2, 3, 4]:
			RunState.placed_tiles[Vector2i(x, y)] = PROTECTION
	add_child_autofree(arena)
	
	for tile in arena.board.unit_grid.forbidden_tiles:
		assert_false(arena.board.unit_grid.special_tiles.has(tile), "%s" % tile)


# --- Placing tiles ---

func test_tray_lists_the_unplaced_tiles() -> void:
	RunState.tiles = [HUNTER, PHANTOM]
	var arena: Arena = preload("res://scenes/arena/arena.tscn").instantiate()
	arena.encounter = ArenaHelper.three_pawns()
	add_child_autofree(arena)
	
	assert_true(arena.tile_tray.visible)
	assert_eq(arena.tile_tray.get_child_count(), 2)


func test_tray_is_hidden_without_tiles() -> void:
	var arena := ArenaHelper.create_arena(self)
	
	assert_false(arena.tile_tray.visible)


func _arena_with_tray(tiles: Array[SpecialTileData]) -> Arena:
	RunState.reset()
	RunState.tiles = tiles
	var arena: Arena = preload("res://scenes/arena/arena.tscn").instantiate()
	arena.encounter = ArenaHelper.three_pawns()
	add_child_autofree(arena)
	return arena


func test_select_then_place_a_tile() -> void:
	var arena := _arena_with_tray([HUNTER])
	var tray := arena.tile_tray
	
	tray.select(0)
	assert_true(tray.place(Vector2i(2, 3)))
	
	assert_eq(RunState.placed_tiles, {Vector2i(2, 3): HUNTER} as Dictionary[Vector2i, SpecialTileData])
	assert_eq(RunState.tiles.size(), 0)
	assert_eq(arena.board.unit_grid.special_tiles[Vector2i(2, 3)], HUNTER)
	assert_eq(tray.selected_index, -1)


func test_tiles_go_only_on_free_player_tiles() -> void:
	var arena := _arena_with_tray([HUNTER, PHANTOM])
	var tray := arena.tile_tray
	tray.select(0)
	
	assert_false(tray.place(Vector2i(2, 2)), "enemy rows")
	arena.board.unit_grid.forbidden_tiles[Vector2i(0, 4)] = Team.WHITE
	assert_false(tray.place(Vector2i(0, 4)), "cursed")
	assert_true(tray.place(Vector2i(1, 4)))
	tray.select(0)
	assert_false(tray.place(Vector2i(1, 4)), "already has a tile")


func test_nothing_is_placed_without_a_selection() -> void:
	var arena := _arena_with_tray([HUNTER])
	
	assert_false(arena.tile_tray.place(Vector2i(2, 3)))


func test_pick_a_tile_back_up() -> void:
	var arena := _arena_with_tray([HUNTER])
	arena.tile_tray.select(0)
	arena.tile_tray.place(Vector2i(2, 3))
	
	assert_true(arena.tile_tray.pick_up(Vector2i(2, 3)))
	
	assert_eq(RunState.tiles, [HUNTER] as Array[SpecialTileData])
	assert_true(RunState.placed_tiles.is_empty())
	assert_false(arena.board.unit_grid.special_tiles.has(Vector2i(2, 3)))


func test_tiles_are_locked_once_the_battle_starts() -> void:
	var arena := _arena_with_tray([HUNTER])
	arena.tile_tray.select(0)
	arena.tile_tray.place(Vector2i(2, 3))
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	arena.preparation.start_battle()
	
	assert_false(arena.tile_tray.pick_up(Vector2i(2, 3)))
	assert_false(arena.tile_tray.visible)


func test_tray_tooltip() -> void:
	var arena := _arena_with_tray([PHANTOM])
	
	(arena.tile_tray.get_child(0) as Button).mouse_entered.emit()
	
	assert_eq(Tooltip.title.text, "Phantom")
	assert_eq(Tooltip.body.text, PHANTOM.description)


# --- RunState / progress ---

func test_place_and_unplace_in_run_state() -> void:
	RunState.tiles = [HUNTER, PHANTOM]
	
	assert_true(RunState.place_tile(1, Vector2i(0, 4)))
	assert_false(RunState.place_tile(0, Vector2i(0, 4)), "occupied")
	assert_eq(RunState.get_tile_count(), 2)
	assert_true(RunState.unplace_tile(Vector2i(0, 4)))
	assert_eq(RunState.tiles, [HUNTER, PHANTOM] as Array[SpecialTileData])


func test_reset_clears_tiles() -> void:
	RunState.tiles = [HUNTER]
	RunState.placed_tiles[Vector2i(0, 4)] = PHANTOM
	
	RunState.reset()
	
	assert_eq(RunState.get_tile_count(), 0)


func test_claiming_a_tile_discovers_it() -> void:
	Progress.clear()
	RunState.pending_choices = [HUNTER]
	
	RunState.claim_choice(0)
	
	assert_true(Progress.is_discovered(HUNTER))
	assert_eq(RunState.tiles, [HUNTER] as Array[SpecialTileData])
	Progress.clear()


func test_collection_has_a_tiles_tab() -> void:
	Progress.clear()
	Progress.discover(PHANTOM)
	var screen: CollectionScreen = add_child_autofree(COLLECTION.instantiate())
	screen.back_scene = ""
	
	screen.tab_buttons[CollectionScreen.Tab.TILES].pressed.emit()
	
	assert_eq(screen.counter_label.text, "Tiles 1/%d" % RunState.TILE_POOL.size())
	Progress.clear()
