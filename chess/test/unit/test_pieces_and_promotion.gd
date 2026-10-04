extends GutTest

const Type := UnitStats.Type
const Team := UnitStats.Team
const PIECES_DIR := "res://data/pieces/%s_%s.tres"
const TYPE_NAMES := ["pawn", "knight", "bishop", "rook", "queen", "king"]


func _load(team: String, type_name: String) -> UnitStats:
	return load(PIECES_DIR % [team, type_name])


# --- Piece data ---

func test_every_piece_exists_for_both_teams() -> void:
	for team_name in ["white", "black"]:
		for i in TYPE_NAMES.size():
			var piece := _load(team_name, TYPE_NAMES[i])
			assert_eq(piece.type, i, "%s %s type" % [team_name, TYPE_NAMES[i]])
			assert_eq(piece.team, Team.WHITE if team_name == "white" else Team.BLACK)
			assert_gt(piece.price, 0)


func test_every_piece_has_its_own_sprite() -> void:
	var seen := {}
	for team_name in ["white", "black"]:
		for type_name in TYPE_NAMES:
			var coords := _load(team_name, type_name).skin_coordinates
			assert_false(seen.has(coords), "%s %s reuses sprite %s" % [team_name, type_name, coords])
			seen[coords] = true
			assert_true(Rect2i(0, 0, 3, 4).has_point(coords), "sprite inside piece.png")


func test_sprite_layout_matches_piece_png() -> void:
	# Top row: pawn, king, knight. Bottom row: bishop, rook, queen.
	assert_eq(_load("white", "king").skin_coordinates, Vector2i(1, 2))
	assert_eq(_load("white", "queen").skin_coordinates, Vector2i(2, 3))
	assert_eq(_load("black", "rook").skin_coordinates, Vector2i(1, 1))
	assert_eq(_load("black", "bishop").skin_coordinates, Vector2i(0, 1))


func test_only_pawns_promote_and_to_their_own_queen() -> void:
	for team_name in ["white", "black"]:
		for type_name in TYPE_NAMES:
			var piece := _load(team_name, type_name)
			if type_name == "pawn":
				assert_eq(piece.promotes_to, _load(team_name, "queen"))
			else:
				assert_null(piece.promotes_to, "%s %s" % [team_name, type_name])


func test_shop_sells_every_white_piece() -> void:
	assert_eq(RunState.SHOP_POOL.size(), RunState.SHOP_WEIGHTS.size())
	for type_name in TYPE_NAMES:
		assert_has(RunState.SHOP_POOL, _load("white", type_name))


func test_tooltip_theme_is_small() -> void:
	var theme := ThemeDB.get_project_theme()
	
	assert_not_null(theme, "project theme is set")
	assert_eq(theme.get_font_size("font_size", "TooltipLabel"), 5)
	assert_true(theme.has_stylebox("panel", "TooltipPanel"))


# --- Promotion rules ---

func test_white_pawn_promotes_on_top_row() -> void:
	var pawn := _load("white", "pawn")
	var board := PieceFactory.board_with({Vector2i(2, 1): pawn})
	
	board.move_piece(Vector2i(2, 1), Vector2i(2, 0))
	
	assert_eq(board.get_piece(Vector2i(2, 0)), _load("white", "queen"))


func test_black_pawn_promotes_on_bottom_row() -> void:
	var pawn := _load("black", "pawn")
	var board := PieceFactory.board_with({Vector2i(2, 3): pawn})
	
	board.move_piece(Vector2i(2, 3), Vector2i(2, 4))
	
	assert_eq(board.get_piece(Vector2i(2, 4)), _load("black", "queen"))


func test_pawn_does_not_promote_before_last_row() -> void:
	var pawn := _load("white", "pawn")
	var board := PieceFactory.board_with({Vector2i(2, 3): pawn})
	
	board.move_piece(Vector2i(2, 3), Vector2i(2, 2))
	
	assert_eq(board.get_piece(Vector2i(2, 2)), pawn)


func test_promotion_by_capture() -> void:
	var pawn := _load("white", "pawn")
	var board := PieceFactory.board_with({
		Vector2i(2, 1): pawn,
		Vector2i(3, 0): _load("black", "rook"),
	})
	
	var captured := board.move_piece(Vector2i(2, 1), Vector2i(3, 0))
	
	assert_eq(captured, _load("black", "rook"))
	assert_eq(board.get_piece(Vector2i(3, 0)), _load("white", "queen"))


func test_ai_values_promotion_and_restores_the_board() -> void:
	var pawn := _load("black", "pawn")
	var board := PieceFactory.board_with({
		Vector2i(0, 3): pawn,
		Vector2i(4, 0): _load("white", "pawn"),
	})
	
	var move := ChessAI.choose_move(board, Team.BLACK, 2)
	
	assert_eq([move.from, move.to], [Vector2i(0, 3), Vector2i(0, 4)], "promoting is the best move")
	assert_eq(board.get_piece(Vector2i(0, 3)), pawn, "search undid the promotion")
	assert_true(board.is_empty(Vector2i(0, 4)))


# --- Promotion in the arena ---

func _arena_with_pawn_about_to_promote() -> Array:
	var arena := ArenaHelper.create_arena(self)
	var pawn := ArenaHelper.place_unit(arena, Vector2i(0, 1), _load("white", "pawn"))
	arena.preparation.start_battle()
	return [arena, pawn]


func test_promotion_waits_for_the_player_choice() -> void:
	var setup := _arena_with_pawn_about_to_promote()
	var arena: Arena = setup[0]
	var pawn: Unit = setup[1]
	
	assert_true(arena.unit_mover.perform_board_move(pawn, Vector2i(0, 1), Vector2i(0, 0)))
	
	assert_true(arena.unit_mover.is_waiting_for_promotion())
	assert_eq(pawn.stats, _load("white", "pawn"), "not promoted yet")
	assert_eq(arena.turn_manager.current_team, Team.WHITE, "the turn is not over")
	assert_true(arena.promotion_panel.visible)
	assert_eq(arena.promotion_panel.options.get_child_count(), 4)
	assert_false(pawn.drag_and_drop.enabled, "nothing can be dragged meanwhile")


func test_choosing_a_piece_promotes_and_ends_the_turn() -> void:
	var setup := _arena_with_pawn_about_to_promote()
	var arena: Arena = setup[0]
	var pawn: Unit = setup[1]
	arena.unit_mover.perform_board_move(pawn, Vector2i(0, 1), Vector2i(0, 0))
	
	# Options: queen, rook, bishop, knight.
	(arena.promotion_panel.options.get_child(3) as Button).pressed.emit()
	
	assert_eq(pawn.stats, _load("white", "knight"))
	assert_eq(pawn.promoted_from, _load("white", "pawn"))
	assert_eq(pawn.skin.region_rect.position, Vector2(_load("white", "knight").skin_coordinates) * 8)
	assert_false(arena.promotion_panel.visible)
	assert_false(arena.unit_mover.is_waiting_for_promotion())
	assert_eq(arena.turn_manager.current_team, Team.BLACK)


func test_promotion_options_tooltips() -> void:
	var setup := _arena_with_pawn_about_to_promote()
	var arena: Arena = setup[0]
	arena.unit_mover.perform_board_move(setup[1], Vector2i(0, 1), Vector2i(0, 0))
	
	(arena.promotion_panel.options.get_child(1) as Button).mouse_entered.emit()
	
	assert_eq(Tooltip.title.text, "Rook")
	Tooltip.hide_tooltip()


func test_enemy_pawns_still_promote_to_queen_right_away() -> void:
	var arena := ArenaHelper.create_arena(self)
	var black_pawn := ArenaHelper.place_unit(arena, Vector2i(4, 3), _load("black", "pawn"))
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	arena.preparation.start_battle()
	arena.turn_manager.end_turn(arena.board.unit_grid.to_board_state())
	
	arena.unit_mover.perform_board_move(black_pawn, Vector2i(4, 3), Vector2i(4, 4))
	
	assert_eq(black_pawn.stats, _load("black", "queen"))
	assert_false(arena.unit_mover.is_waiting_for_promotion())


func test_pawns_offer_four_promotions() -> void:
	for team_name in ["white", "black"]:
		var options := _load(team_name, "pawn").promotion_options
		assert_eq(options, [
			_load(team_name, "queen"), _load(team_name, "rook"),
			_load(team_name, "bishop"), _load(team_name, "knight"),
		] as Array[Resource])


func test_captured_promoted_piece_goes_to_graveyard_as_pawn() -> void:
	var arena := ArenaHelper.create_arena(self)
	RunState.pieces = [_load("white", "pawn"), _load("white", "knight")]
	var queen := ArenaHelper.place_unit(arena, Vector2i(2, 2), _load("white", "pawn"))
	queen.promote(_load("white", "queen"))
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	arena.preparation.start_battle()
	arena.turn_manager.end_turn(arena.board.unit_grid.to_board_state())
	var black_pawn: Unit = arena.board.unit_grid.units[Vector2i(1, 1)]
	
	arena.unit_mover.perform_board_move(black_pawn, Vector2i(1, 1), Vector2i(2, 2))
	
	assert_eq(RunState.graveyard, [_load("white", "pawn")] as Array[UnitStats])
