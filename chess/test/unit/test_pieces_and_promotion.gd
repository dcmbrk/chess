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

func test_unit_promotes_when_reaching_last_row() -> void:
	var arena := ArenaHelper.create_arena(self)
	var pawn := ArenaHelper.place_unit(arena, Vector2i(0, 1), _load("white", "pawn"))
	arena.preparation.start_battle()
	
	assert_true(arena.unit_mover.perform_board_move(pawn, Vector2i(0, 1), Vector2i(0, 0)))
	
	assert_eq(pawn.stats, _load("white", "queen"))
	assert_eq(pawn.promoted_from, _load("white", "pawn"))
	assert_eq(pawn.get_run_stats(), _load("white", "pawn"))
	assert_eq(pawn.skin.region_rect.position, Vector2(_load("white", "queen").skin_coordinates) * 8)


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
