extends GutTest

const Type := UnitStats.Type
const Team := UnitStats.Team
const Result := GameRules.Result

var turn_manager: TurnManager


func before_each() -> void:
	turn_manager = TurnManager.new()
	add_child_autofree(turn_manager)
	watch_signals(turn_manager)


## Both teams have a free pawn, so both can move.
func _open_board() -> BoardState:
	return PieceFactory.board_with({
		Vector2i(0, 4): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(4, 0): PieceFactory.make(Type.PAWN, Team.BLACK),
	})


func test_is_inactive_before_battle() -> void:
	assert_false(turn_manager.active)
	assert_false(turn_manager.can_move(PieceFactory.make(Type.PAWN)))


func test_start_battle_gives_first_turn_to_starting_team() -> void:
	turn_manager.start_battle(_open_board())

	assert_true(turn_manager.active)
	assert_eq(turn_manager.current_team, Team.WHITE)
	assert_eq(turn_manager.result, Result.ONGOING)
	assert_signal_emitted_with_parameters(turn_manager, "turn_started", [Team.WHITE])


func test_starting_team_can_be_black() -> void:
	turn_manager.starting_team = Team.BLACK
	turn_manager.start_battle(_open_board())

	assert_eq(turn_manager.current_team, Team.BLACK)


func test_end_turn_alternates_teams() -> void:
	var board := _open_board()
	turn_manager.start_battle(board)

	turn_manager.end_turn(board)
	assert_eq(turn_manager.current_team, Team.BLACK)

	turn_manager.end_turn(board)
	assert_eq(turn_manager.current_team, Team.WHITE)
	assert_signal_emit_count(turn_manager, "turn_started", 3)


func test_only_current_team_can_move() -> void:
	turn_manager.start_battle(_open_board())

	assert_true(turn_manager.can_move(PieceFactory.make(Type.PAWN, Team.WHITE)))
	assert_false(turn_manager.can_move(PieceFactory.make(Type.PAWN, Team.BLACK)))
	assert_false(turn_manager.can_move(null))


func test_is_legal_move() -> void:
	var board := _open_board()
	turn_manager.start_battle(board)

	assert_true(turn_manager.is_legal_move(board, Vector2i(0, 4), Vector2i(0, 3)), "legal pawn move")
	assert_false(turn_manager.is_legal_move(board, Vector2i(0, 4), Vector2i(0, 2)), "too far")
	assert_false(turn_manager.is_legal_move(board, Vector2i(4, 0), Vector2i(4, 1)), "not black's turn")
	assert_false(turn_manager.is_legal_move(board, Vector2i(2, 2), Vector2i(2, 1)), "empty tile")


# --- Battle end ---

func test_capturing_all_enemies_wins() -> void:
	var board := _open_board()
	turn_manager.start_battle(board)

	board.set_piece(Vector2i(4, 0), null)
	turn_manager.end_turn(board)

	assert_false(turn_manager.active)
	assert_eq(turn_manager.result, Result.WHITE_WINS)
	assert_signal_emitted_with_parameters(turn_manager, "battle_ended", [Result.WHITE_WINS])
	assert_false(turn_manager.can_move(PieceFactory.make(Type.PAWN, Team.BLACK)))


func test_losing_all_pieces_loses() -> void:
	var board := _open_board()
	turn_manager.start_battle(board)
	turn_manager.end_turn(board)

	board.set_piece(Vector2i(0, 4), null)
	turn_manager.end_turn(board)

	assert_eq(turn_manager.result, Result.BLACK_WINS)


func test_capturing_king_wins_even_with_pieces_left() -> void:
	var board := _open_board()
	board.set_piece(Vector2i(2, 0), PieceFactory.make(Type.KING, Team.BLACK))
	turn_manager.start_battle(board)

	board.set_piece(Vector2i(2, 0), null)
	turn_manager.end_turn(board)

	assert_eq(turn_manager.result, Result.WHITE_WINS)


func test_team_without_king_at_start_does_not_need_one() -> void:
	var board := _open_board()
	board.set_piece(Vector2i(2, 4), PieceFactory.make(Type.KING, Team.WHITE))
	turn_manager.start_battle(board)

	turn_manager.end_turn(board)

	assert_true(turn_manager.active, "black never had a king")


func test_battle_can_end_immediately_at_start() -> void:
	var board := PieceFactory.board_with({
		Vector2i(0, 4): PieceFactory.make(Type.PAWN, Team.WHITE),
	})

	turn_manager.start_battle(board)

	assert_eq(turn_manager.result, Result.WHITE_WINS)
	assert_signal_not_emitted(turn_manager, "turn_started")


# --- No legal moves ---

func test_team_without_moves_is_skipped() -> void:
	# The black pawn is blocked by the white pawn below it.
	var board := PieceFactory.board_with({
		Vector2i(0, 4): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(2, 2): PieceFactory.make(Type.PAWN, Team.BLACK),
		Vector2i(2, 3): PieceFactory.make(Type.ROOK, Team.WHITE),
	})
	turn_manager.start_battle(board)

	turn_manager.end_turn(board)

	assert_eq(turn_manager.current_team, Team.WHITE)
	assert_signal_emitted_with_parameters(turn_manager, "turn_skipped", [Team.BLACK])


func test_no_moves_for_both_teams_is_a_draw() -> void:
	# Two pawns blocking each other.
	var board := PieceFactory.board_with({
		Vector2i(2, 3): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(2, 2): PieceFactory.make(Type.PAWN, Team.BLACK),
	})

	turn_manager.start_battle(board)

	assert_false(turn_manager.active)
	assert_eq(turn_manager.result, Result.DRAW)
