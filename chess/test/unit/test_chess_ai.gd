extends GutTest

const Type := UnitStats.Type
const Team := UnitStats.Team


func _assert_move(move: ChessMove, from: Vector2i, to: Vector2i) -> void:
	assert_not_null(move)
	if move:
		assert_eq([move.from, move.to], [from, to])


func test_evaluate_counts_material_from_team_point_of_view() -> void:
	var board := PieceFactory.board_with({
		Vector2i(0, 0): PieceFactory.make(Type.ROOK, Team.WHITE),
		Vector2i(1, 0): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(4, 4): PieceFactory.make(Type.KNIGHT, Team.BLACK),
	})

	assert_eq(ChessAI.evaluate(board, Team.WHITE), 3)
	assert_eq(ChessAI.evaluate(board, Team.BLACK), -3)


func test_returns_null_without_moves() -> void:
	var board := PieceFactory.board_with({
		Vector2i(2, 4): PieceFactory.make(Type.PAWN, Team.BLACK),
	})

	assert_null(ChessAI.choose_move(board, Team.BLACK, 2))
	assert_null(ChessAI.choose_move(PieceFactory.board_with({}), Team.BLACK, 2))


func test_greedy_takes_most_valuable_piece() -> void:
	var board := PieceFactory.board_with({
		Vector2i(2, 2): PieceFactory.make(Type.QUEEN, Team.BLACK),
		Vector2i(2, 4): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(4, 2): PieceFactory.make(Type.ROOK, Team.WHITE),
	})

	_assert_move(ChessAI.choose_move(board, Team.BLACK, 1), Vector2i(2, 2), Vector2i(4, 2))


func test_captures_king_when_possible() -> void:
	var board := PieceFactory.board_with({
		Vector2i(2, 2): PieceFactory.make(Type.ROOK, Team.BLACK),
		Vector2i(2, 4): PieceFactory.make(Type.KING, Team.WHITE),
		Vector2i(4, 2): PieceFactory.make(Type.QUEEN, Team.WHITE),
	})

	_assert_move(ChessAI.choose_move(board, Team.BLACK, 2), Vector2i(2, 2), Vector2i(2, 4))


func test_depth_two_avoids_defended_piece() -> void:
	# The white pawn on (2, 2) is defended by the white pawn on (1, 3).
	var board := PieceFactory.board_with({
		Vector2i(0, 0): PieceFactory.make(Type.QUEEN, Team.BLACK),
		Vector2i(2, 2): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(1, 3): PieceFactory.make(Type.PAWN, Team.WHITE),
	})

	var greedy := ChessAI.choose_move(board, Team.BLACK, 1)
	var careful := ChessAI.choose_move(board, Team.BLACK, 2)

	_assert_move(greedy, Vector2i(0, 0), Vector2i(2, 2))
	assert_ne(careful.to, Vector2i(2, 2), "should not trade the queen for a pawn")


func test_search_leaves_board_unchanged() -> void:
	var pieces := {
		Vector2i(0, 0): PieceFactory.make(Type.QUEEN, Team.BLACK),
		Vector2i(3, 0): PieceFactory.make(Type.KNIGHT, Team.BLACK),
		Vector2i(2, 2): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(1, 3): PieceFactory.make(Type.ROOK, Team.WHITE),
		Vector2i(4, 4): PieceFactory.make(Type.KING, Team.WHITE),
	}
	var board := PieceFactory.board_with(pieces)

	ChessAI.choose_move(board, Team.BLACK, 3)

	for x in 5:
		for y in 5:
			var tile := Vector2i(x, y)
			assert_eq(board.get_piece(tile), pieces.get(tile), "tile %s" % tile)


func test_rng_picks_among_equally_good_moves() -> void:
	var board := PieceFactory.board_with({
		Vector2i(2, 2): PieceFactory.make(Type.KING, Team.BLACK),
	})
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var seen := {}

	for i in 30:
		var move := ChessAI.choose_move(board, Team.BLACK, 1, rng)
		seen[move.to] = true

	assert_gt(seen.size(), 1, "different moves should be picked")
