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


# --- Statuses on the board model ---

func test_protected_unit_cannot_be_captured() -> void:
	var board := PieceFactory.board_with({
		Vector2i(2, 3): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(2, 0): PieceFactory.make(Type.ROOK, Team.BLACK),
	})
	board.protected_tiles[Vector2i(2, 3)] = Team.WHITE
	
	assert_does_not_have(MoveRules.get_legal_moves(board, Vector2i(2, 0)), Vector2i(2, 3))


func test_holes_block_everybody() -> void:
	var board := PieceFactory.board_with({
		Vector2i(0, 0): PieceFactory.make(Type.ROOK, Team.BLACK),
		Vector2i(4, 4): PieceFactory.make(Type.ROOK, Team.WHITE),
	})
	board.holes[Vector2i(0, 2)] = true
	board.holes[Vector2i(4, 2)] = true
	
	var black := MoveRules.get_legal_moves(board, Vector2i(0, 0))
	assert_does_not_have(black, Vector2i(0, 2))
	assert_does_not_have(black, Vector2i(0, 3), "can't slide over a hole")
	assert_does_not_have(MoveRules.get_legal_moves(board, Vector2i(4, 4)), Vector2i(4, 2))


func test_grid_turns_unit_statuses_into_rules() -> void:
	var arena := ArenaHelper.create_arena(self)
	var pawn := ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(2, 4))
	var black: Unit = arena.board.unit_grid.units[Vector2i(1, 1)]
	pawn.is_protected = true
	black.is_trapped = true
	
	var board := arena.board.unit_grid.to_board_state()
	
	assert_true(board.is_protected(Vector2i(2, 4)))
	assert_true(board.is_frozen(Vector2i(1, 1)))


# --- Effects in the arena (like the original game) ---

func _arena_with_tiles(placed: Dictionary) -> Arena:
	var arena := ArenaHelper.create_arena(self)
	for tile: Vector2i in placed:
		arena.board.unit_grid.special_tiles[tile] = placed[tile]
	return arena


func test_protective_tile_protects_during_the_enemy_turn_only() -> void:
	var arena := _arena_with_tiles({Vector2i(4, 3): PROTECTION})
	var pawn := ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(4, 4))
	arena.preparation.start_battle()
	
	arena.unit_mover.perform_board_move(pawn, Vector2i(4, 4), Vector2i(4, 3))
	assert_true(pawn.is_protected, "protected during the enemy turn")
	assert_eq(arena.turn_manager.current_team, Team.BLACK)
	
	arena.unit_mover.end_turn()
	
	assert_false(pawn.is_protected, "gone on the player's next turn")


func test_blessed_piece_returns_to_the_stock_when_captured() -> void:
	var arena := _arena_with_tiles({Vector2i(2, 3): BENEDICTION})
	var pawn := ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(2, 4))
	arena.preparation.start_battle()
	arena.unit_mover.perform_board_move(pawn, Vector2i(2, 4), Vector2i(2, 3))
	assert_true(pawn.is_blessed)
	# A black rook captures it.
	var rook := ArenaHelper.place_unit(arena, Vector2i(2, 0), BLACK_ROOK)
	var blocker: Unit = arena.board.unit_grid.units[Vector2i(2, 1)]
	arena.board.unit_grid.remove_unit(Vector2i(2, 1))
	blocker.free()
	var bench_before: int = arena.get_node("Bench").unit_grid.get_all_units().size()
	
	arena.unit_mover.perform_board_move(rook, Vector2i(2, 0), Vector2i(2, 3))
	
	assert_eq(RunState.graveyard.size(), 0, "not lost")
	assert_has(RunState.pieces, WHITE_PAWN)
	assert_eq(arena.get_node("Bench").unit_grid.get_all_units().size(), bench_before + 1, "back on the bench")


func test_trap_makes_the_enemy_skip_its_next_turn() -> void:
	var arena := _arena_with_tiles({Vector2i(1, 2): HUNTER})
	var pawn := ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(4, 4))
	arena.preparation.start_battle()
	arena.unit_mover.end_turn() # white waits
	var black_pawn: Unit = arena.board.unit_grid.units[Vector2i(1, 1)]
	
	arena.unit_mover.perform_board_move(black_pawn, Vector2i(1, 1), Vector2i(1, 2))
	assert_true(black_pawn.is_trapped)
	arena.unit_mover.perform_board_move(pawn, Vector2i(4, 4), Vector2i(4, 3))
	
	assert_eq(arena.turn_manager.current_team, Team.BLACK)
	assert_eq(MoveRules.get_legal_moves(arena.board.unit_grid.to_board_state(), Vector2i(1, 2)), [] as Array[Vector2i], "stuck this turn")
	arena.unit_mover.end_turn()
	assert_false(black_pawn.is_trapped, "free again afterwards")


func test_trap_ignores_the_player_pieces() -> void:
	var arena := _arena_with_tiles({Vector2i(4, 3): HUNTER})
	var pawn := ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(4, 4))
	arena.preparation.start_battle()
	
	arena.unit_mover.perform_board_move(pawn, Vector2i(4, 4), Vector2i(4, 3))
	
	assert_false(pawn.is_trapped)


func test_phantom_tile_adds_a_temporary_copy_to_the_stock() -> void:
	var arena := _arena_with_tiles({Vector2i(4, 3): PHANTOM})
	var pawn := ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(4, 4))
	var bench_grid: UnitGrid = arena.get_node("Bench").unit_grid
	arena.preparation.start_battle()
	
	arena.unit_mover.perform_board_move(pawn, Vector2i(4, 4), Vector2i(4, 3))
	
	var copies := bench_grid.get_all_units().filter(func(u: Unit) -> bool: return u.is_temporary)
	assert_eq(copies.size(), 1)
	assert_eq(copies[0].stats, WHITE_PAWN)
	assert_eq(RunState.pieces.count(WHITE_PAWN), 1, "the copy is not added to the run")


func test_phantom_tile_works_once_per_battle() -> void:
	var arena := _arena_with_tiles({Vector2i(4, 3): PHANTOM})
	var pawn := ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(4, 4))
	arena.preparation.start_battle()
	
	arena.tile_effects._on_unit_landed(pawn, Vector2i(4, 3))
	arena.tile_effects._on_unit_landed(pawn, Vector2i(4, 3))
	
	var copies := (arena.get_node("Bench").unit_grid as UnitGrid).get_all_units().filter(func(u: Unit) -> bool: return u.is_temporary)
	assert_eq(copies.size(), 1)


func test_captured_phantom_copy_just_vanishes() -> void:
	var arena := ArenaHelper.create_arena(self)
	var copy := ArenaHelper.place_unit(arena, Vector2i(2, 2), WHITE_PAWN)
	copy.is_temporary = true
	
	arena._on_unit_captured(copy, null)
	
	assert_eq(RunState.graveyard.size(), 0)


func test_tooltip_lists_statuses() -> void:
	var arena := ArenaHelper.create_arena(self)
	var pawn := ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(2, 4))
	pawn.is_blessed = true
	pawn.is_protected = true
	
	assert_string_contains(UnitTooltip.get_status_text(pawn), "Blessed")
	assert_string_contains(UnitTooltip.get_status_text(pawn), "Protected")


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
