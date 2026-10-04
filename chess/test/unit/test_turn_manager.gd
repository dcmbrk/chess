extends GutTest

const Type := UnitStats.Type
const Team := UnitStats.Team

var turn_manager: TurnManager


func before_each() -> void:
	turn_manager = TurnManager.new()
	add_child_autofree(turn_manager)


func test_is_inactive_before_battle() -> void:
	assert_false(turn_manager.active)
	assert_false(turn_manager.can_move(PieceFactory.make(Type.PAWN)))


func test_start_battle_gives_first_turn_to_starting_team() -> void:
	watch_signals(turn_manager)
	
	turn_manager.start_battle()
	
	assert_true(turn_manager.active)
	assert_eq(turn_manager.current_team, Team.WHITE)
	assert_signal_emitted_with_parameters(turn_manager, "turn_started", [Team.WHITE])


func test_starting_team_can_be_black() -> void:
	turn_manager.starting_team = Team.BLACK
	turn_manager.start_battle()
	
	assert_eq(turn_manager.current_team, Team.BLACK)


func test_end_turn_alternates_teams() -> void:
	turn_manager.start_battle()
	watch_signals(turn_manager)
	
	turn_manager.end_turn()
	assert_eq(turn_manager.current_team, Team.BLACK)
	
	turn_manager.end_turn()
	assert_eq(turn_manager.current_team, Team.WHITE)
	assert_signal_emit_count(turn_manager, "turn_started", 2)


func test_get_opponent() -> void:
	assert_eq(TurnManager.get_opponent(Team.WHITE), Team.BLACK)
	assert_eq(TurnManager.get_opponent(Team.BLACK), Team.WHITE)


func test_only_current_team_can_move() -> void:
	turn_manager.start_battle()
	
	assert_true(turn_manager.can_move(PieceFactory.make(Type.PAWN, Team.WHITE)))
	assert_false(turn_manager.can_move(PieceFactory.make(Type.PAWN, Team.BLACK)))
	assert_false(turn_manager.can_move(null))


func test_is_legal_move() -> void:
	var board := PieceFactory.board_with({
		Vector2i(2, 2): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(0, 0): PieceFactory.make(Type.PAWN, Team.BLACK),
	})
	turn_manager.start_battle()
	
	assert_true(turn_manager.is_legal_move(board, Vector2i(2, 2), Vector2i(2, 1)), "legal pawn move")
	assert_false(turn_manager.is_legal_move(board, Vector2i(2, 2), Vector2i(2, 0)), "too far")
	assert_false(turn_manager.is_legal_move(board, Vector2i(0, 0), Vector2i(0, 1)), "not black's turn")
	assert_false(turn_manager.is_legal_move(board, Vector2i(4, 4), Vector2i(4, 3)), "empty tile")
