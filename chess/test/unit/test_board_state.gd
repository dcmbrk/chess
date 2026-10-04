extends GutTest

const Type := UnitStats.Type
const Team := UnitStats.Team

var board: BoardState


func before_each() -> void:
	board = BoardState.new(Vector2i(5, 5))


func test_is_in_bounds() -> void:
	assert_true(board.is_in_bounds(Vector2i(0, 0)))
	assert_true(board.is_in_bounds(Vector2i(4, 4)))
	assert_false(board.is_in_bounds(Vector2i(5, 0)))
	assert_false(board.is_in_bounds(Vector2i(0, 5)))
	assert_false(board.is_in_bounds(Vector2i(-1, 2)))


func test_new_board_is_empty() -> void:
	assert_true(board.is_empty(Vector2i(2, 2)))
	assert_null(board.get_piece(Vector2i(2, 2)))


func test_set_and_get_piece() -> void:
	var pawn := PieceFactory.make(Type.PAWN)
	board.set_piece(Vector2i(1, 3), pawn)

	assert_eq(board.get_piece(Vector2i(1, 3)), pawn)
	assert_false(board.is_empty(Vector2i(1, 3)))


func test_set_null_removes_piece() -> void:
	board.set_piece(Vector2i(1, 3), PieceFactory.make(Type.PAWN))
	board.set_piece(Vector2i(1, 3), null)

	assert_true(board.is_empty(Vector2i(1, 3)))


func test_is_enemy() -> void:
	board.set_piece(Vector2i(0, 0), PieceFactory.make(Type.PAWN, Team.BLACK))

	assert_true(board.is_enemy(Vector2i(0, 0), Team.WHITE))
	assert_false(board.is_enemy(Vector2i(0, 0), Team.BLACK))
	assert_false(board.is_enemy(Vector2i(1, 1), Team.WHITE), "empty tile is not an enemy")


func test_move_piece_to_empty_tile() -> void:
	var rook := PieceFactory.make(Type.ROOK)
	board.set_piece(Vector2i(0, 0), rook)
	
	var captured := board.move_piece(Vector2i(0, 0), Vector2i(0, 3))
	
	assert_null(captured)
	assert_true(board.is_empty(Vector2i(0, 0)))
	assert_eq(board.get_piece(Vector2i(0, 3)), rook)


func test_move_piece_returns_captured_piece() -> void:
	var rook := PieceFactory.make(Type.ROOK)
	var enemy := PieceFactory.make(Type.PAWN, Team.BLACK)
	board.set_piece(Vector2i(0, 0), rook)
	board.set_piece(Vector2i(0, 3), enemy)
	
	var captured := board.move_piece(Vector2i(0, 0), Vector2i(0, 3))
	
	assert_eq(captured, enemy)
	assert_eq(board.get_piece(Vector2i(0, 3)), rook)
