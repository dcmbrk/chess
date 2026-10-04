extends GutTest

const Type := UnitStats.Type
const Team := UnitStats.Team
const Result := GameRules.Result

const NO_KINGS := {Team.WHITE: false, Team.BLACK: false}


func test_count_pieces() -> void:
	var board := PieceFactory.board_with({
		Vector2i(0, 0): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(1, 0): PieceFactory.make(Type.ROOK, Team.WHITE),
		Vector2i(4, 4): PieceFactory.make(Type.PAWN, Team.BLACK),
	})

	assert_eq(GameRules.count_pieces(board, Team.WHITE), 2)
	assert_eq(GameRules.count_pieces(board, Team.BLACK), 1)


func test_has_king() -> void:
	var board := PieceFactory.board_with({
		Vector2i(0, 0): PieceFactory.make(Type.KING, Team.WHITE),
		Vector2i(4, 4): PieceFactory.make(Type.QUEEN, Team.BLACK),
	})

	assert_true(GameRules.has_king(board, Team.WHITE))
	assert_false(GameRules.has_king(board, Team.BLACK))


func test_has_legal_moves() -> void:
	var board := PieceFactory.board_with({
		Vector2i(0, 4): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(2, 4): PieceFactory.make(Type.PAWN, Team.BLACK),
	})

	assert_true(GameRules.has_legal_moves(board, Team.WHITE))
	assert_false(GameRules.has_legal_moves(board, Team.BLACK), "black pawn is on its last row")


func test_ongoing_when_both_teams_have_pieces() -> void:
	var board := PieceFactory.board_with({
		Vector2i(0, 4): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(4, 0): PieceFactory.make(Type.PAWN, Team.BLACK),
	})

	assert_eq(GameRules.get_result(board, NO_KINGS), Result.ONGOING)


func test_team_without_pieces_loses() -> void:
	var white_only := PieceFactory.board_with({Vector2i(0, 4): PieceFactory.make(Type.PAWN, Team.WHITE)})
	var black_only := PieceFactory.board_with({Vector2i(0, 4): PieceFactory.make(Type.PAWN, Team.BLACK)})

	assert_eq(GameRules.get_result(white_only, NO_KINGS), Result.WHITE_WINS)
	assert_eq(GameRules.get_result(black_only, NO_KINGS), Result.BLACK_WINS)


func test_empty_board_is_a_draw() -> void:
	assert_eq(GameRules.get_result(PieceFactory.board_with({}), NO_KINGS), Result.DRAW)


func test_losing_king_loses_only_when_king_is_needed() -> void:
	var board := PieceFactory.board_with({
		Vector2i(0, 4): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(4, 0): PieceFactory.make(Type.PAWN, Team.BLACK),
	})

	assert_eq(GameRules.get_result(board, {Team.WHITE: false, Team.BLACK: true}), Result.WHITE_WINS)
	assert_eq(GameRules.get_result(board, {Team.WHITE: true, Team.BLACK: false}), Result.BLACK_WINS)
	assert_eq(GameRules.get_result(board, {}), Result.ONGOING, "missing entries mean no king needed")
