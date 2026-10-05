## Chess movement rules for every piece type.
## CURSED tiles block a team like a wall and crumbled tiles (holes) block everybody.
## STASIS, trapped and protected pieces can't be captured (the first two can't move).
## Not implemented: double pawn step, castling, en passant, check.
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

	if not piece or board.is_frozen(from):
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


static func is_last_row(board: BoardState, tile: Vector2i, team: UnitStats.Team) -> bool:
	return tile.y == (0 if team == UnitStats.Team.WHITE else board.size.y - 1)


## The piece [param piece] becomes after moving to [param to], or null.
static func get_promotion(board: BoardState, piece: UnitStats, to: Vector2i) -> UnitStats:
	if piece.promotes_to and is_last_row(board, to, piece.team):
		return piece.promotes_to
	return null


static func _can_land_on(board: BoardState, tile: Vector2i, team: UnitStats.Team) -> bool:
	return _can_enter(board, tile, team) and (board.is_empty(tile) or _can_capture(board, tile, team))


static func _can_enter(board: BoardState, tile: Vector2i, team: UnitStats.Team) -> bool:
	return board.is_in_bounds(tile) and not board.is_forbidden(tile, team) and not board.is_hole(tile)


static func _can_capture(board: BoardState, tile: Vector2i, team: UnitStats.Team) -> bool:
	return board.is_enemy(tile, team) and not board.is_frozen(tile) and not board.is_protected(tile)


static func _get_pawn_moves(board: BoardState, from: Vector2i, team: UnitStats.Team) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var forward := get_forward(team)

	var ahead := from + forward
	if _can_enter(board, ahead, team) and board.is_empty(ahead):
		moves.append(ahead)

	for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
		var capture := from + forward + side
		if _can_enter(board, capture, team) and _can_capture(board, capture, team):
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
