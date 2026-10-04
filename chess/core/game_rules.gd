## Win / lose conditions of a battle.
## A team loses when it has no pieces left, or when it started with a king
## and that king was captured.
class_name GameRules
extends RefCounted

enum Result { ONGOING, WHITE_WINS, BLACK_WINS, DRAW }
## A finished battle's result from one team's point of view.
enum Outcome { WIN, LOSS, DRAW }


static func get_outcome(result: Result, team: UnitStats.Team) -> Outcome:
	assert(result != Result.ONGOING, "The battle is not over yet!")

	if result == Result.DRAW:
		return Outcome.DRAW

	var winner := UnitStats.Team.WHITE if result == Result.WHITE_WINS else UnitStats.Team.BLACK
	return Outcome.WIN if winner == team else Outcome.LOSS


static func count_pieces(board: BoardState, team: UnitStats.Team) -> int:
	var count := 0

	for x in board.size.x:
		for y in board.size.y:
			var piece := board.get_piece(Vector2i(x, y))
			if piece and piece.team == team:
				count += 1

	return count


static func has_king(board: BoardState, team: UnitStats.Team) -> bool:
	for x in board.size.x:
		for y in board.size.y:
			var piece := board.get_piece(Vector2i(x, y))
			if piece and piece.team == team and piece.type == UnitStats.Type.KING:
				return true

	return false


static func has_legal_moves(board: BoardState, team: UnitStats.Team) -> bool:
	return not MoveRules.get_all_moves(board, team).is_empty()


static func is_defeated(board: BoardState, team: UnitStats.Team, needs_king: bool) -> bool:
	return count_pieces(board, team) == 0 or (needs_king and not has_king(board, team))


## [param needs_king] maps each team to whether losing its king loses the battle.
static func get_result(board: BoardState, needs_king: Dictionary) -> Result:
	var white_lost := is_defeated(board, UnitStats.Team.WHITE, needs_king.get(UnitStats.Team.WHITE, false))
	var black_lost := is_defeated(board, UnitStats.Team.BLACK, needs_king.get(UnitStats.Team.BLACK, false))

	if white_lost and black_lost:
		return Result.DRAW
	if white_lost:
		return Result.BLACK_WINS
	if black_lost:
		return Result.WHITE_WINS
	return Result.ONGOING
