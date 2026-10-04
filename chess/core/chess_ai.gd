## Picks moves with a negamax search (minimax + alpha-beta pruning).
## depth 1 = greedy: only looks at the immediate capture.
class_name ChessAI
extends RefCounted

const PIECE_VALUES := {
	UnitStats.Type.PAWN: 1,
	UnitStats.Type.KNIGHT: 3,
	UnitStats.Type.BISHOP: 3,
	UnitStats.Type.ROOK: 5,
	UnitStats.Type.QUEEN: 9,
	UnitStats.Type.KING: 100,
}
const WIN_SCORE := 10000


## Material balance from [param team]'s point of view.
static func evaluate(board: BoardState, team: UnitStats.Team) -> int:
	var score := 0

	for x in board.size.x:
		for y in board.size.y:
			var piece := board.get_piece(Vector2i(x, y))
			if piece:
				var value: int = PIECE_VALUES[piece.type]
				score += value if piece.team == team else -value

	return score


## Returns null when [param team] has no legal move.
## Ties are broken with [param rng] if given, otherwise the first best move wins.
static func choose_move(board: BoardState, team: UnitStats.Team, depth: int, rng: RandomNumberGenerator = null) -> ChessMove:
	assert(depth >= 1, "Search depth must be at least 1!")

	var best_moves: Array[ChessMove] = []
	var best_score := -INF

	for move in MoveRules.get_all_moves(board, team):
		var score := _score_move(board, move, team, depth)
		if score > best_score:
			best_score = score
			best_moves = [move]
		elif score == best_score:
			best_moves.append(move)

	if best_moves.is_empty():
		return null
	if rng:
		return best_moves[rng.randi_range(0, best_moves.size() - 1)]
	return best_moves[0]


static func _score_move(board: BoardState, move: ChessMove, team: UnitStats.Team, depth: int, alpha := -INF, beta := INF) -> float:
	var piece := board.get_piece(move.from)
	var captured := board.move_piece(move.from, move.to)

	var score: float
	if captured and captured.type == UnitStats.Type.KING:
		# Winning sooner (more depth left) is better.
		score = WIN_SCORE + depth
	else:
		score = -_negamax(board, UnitStats.get_opponent(team), depth - 1, -beta, -alpha)

	board.set_piece(move.from, piece)
	board.set_piece(move.to, captured)
	return score


static func _negamax(board: BoardState, team: UnitStats.Team, depth: int, alpha: float, beta: float) -> float:
	if depth == 0:
		return evaluate(board, team)

	var moves := MoveRules.get_all_moves(board, team)
	if moves.is_empty():
		return evaluate(board, team)

	var best := -INF
	for move in moves:
		best = maxf(best, _score_move(board, move, team, depth, alpha, beta))
		alpha = maxf(alpha, best)
		if alpha >= beta:
			break

	return best
