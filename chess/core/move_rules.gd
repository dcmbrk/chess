## Chess movement rules for every piece type.
## Not implemented yet: double pawn step, promotion, castling, en passant, check.
class_name MoveRules
extends RefCounted

const ORTHOGONAL: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
]
const DIAGONAL: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]
const ALL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]
const KNIGHT_OFFSETS: Array[Vector2i] = [
	Vector2i(1, -2), Vector2i(2, -1), Vector2i(2, 1), Vector2i(1, 2),
	Vector2i(-1, 2), Vector2i(-2, 1), Vector2i(-2, -1), Vector2i(-1, -2),
]


static func get_legal_moves(board: BoardState, from: Vector2i) -> Array[Vector2i]:
	var piece := board.get_piece(from)

	if not piece:
		return []

	match piece.type:
		UnitStats.Type.PAWN:
			return _get_pawn_moves(board, from, piece.team)
		UnitStats.Type.KNIGHT:
			return _get_step_moves(board, from, piece.team, KNIGHT_OFFSETS)
		UnitStats.Type.BISHOP:
			return _get_slide_moves(board, from, piece.team, DIAGONAL)
		UnitStats.Type.ROOK:
			return _get_slide_moves(board, from, piece.team, ORTHOGONAL)
		UnitStats.Type.QUEEN:
			return _get_slide_moves(board, from, piece.team, ALL_DIRECTIONS)
		UnitStats.Type.KING:
			return _get_step_moves(board, from, piece.team, ALL_DIRECTIONS)

	return []


static func get_all_moves(board: BoardState, team: UnitStats.Team) -> Array[ChessMove]:
	var moves: Array[ChessMove] = []

	for x in board.size.x:
		for y in board.size.y:
			var from := Vector2i(x, y)
			var piece := board.get_piece(from)
			if piece and piece.team == team:
				for to in get_legal_moves(board, from):
					moves.append(ChessMove.new(from, to))

	return moves


static func get_forward(team: UnitStats.Team) -> Vector2i:
	return Vector2i.UP if team == UnitStats.Team.WHITE else Vector2i.DOWN


static func _can_land_on(board: BoardState, tile: Vector2i, team: UnitStats.Team) -> bool:
	return board.is_in_bounds(tile) and (board.is_empty(tile) or board.is_enemy(tile, team))


static func _get_pawn_moves(board: BoardState, from: Vector2i, team: UnitStats.Team) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var forward := get_forward(team)

	var ahead := from + forward
	if board.is_in_bounds(ahead) and board.is_empty(ahead):
		moves.append(ahead)

	for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
		var capture := from + forward + side
		if board.is_in_bounds(capture) and board.is_enemy(capture, team):
			moves.append(capture)

	return moves


static func _get_step_moves(board: BoardState, from: Vector2i, team: UnitStats.Team, offsets: Array[Vector2i]) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []

	for offset in offsets:
		if _can_land_on(board, from + offset, team):
			moves.append(from + offset)

	return moves


static func _get_slide_moves(board: BoardState, from: Vector2i, team: UnitStats.Team, directions: Array[Vector2i]) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []

	for direction in directions:
		var tile := from + direction
		while _can_land_on(board, tile, team):
			moves.append(tile)
			if not board.is_empty(tile):
				break
			tile += direction

	return moves
