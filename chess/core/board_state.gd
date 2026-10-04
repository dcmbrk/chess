## Pure data snapshot of a board, used by game rules so they can be
## tested without any scene nodes.
## Tile (0, 0) is the top-left corner; WHITE moves towards smaller y.
class_name BoardState
extends RefCounted

var size: Vector2i

var _pieces: Dictionary[Vector2i, UnitStats] = {}


func _init(board_size: Vector2i) -> void:
	size = board_size


func is_in_bounds(tile: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, size).has_point(tile)


func get_piece(tile: Vector2i) -> UnitStats:
	return _pieces.get(tile)


func set_piece(tile: Vector2i, piece: UnitStats) -> void:
	assert(is_in_bounds(tile), "Tile %s is out of bounds!" % tile)

	if piece:
		_pieces[tile] = piece
	else:
		_pieces.erase(tile)


## Moves the piece and returns the captured piece, or null.
func move_piece(from: Vector2i, to: Vector2i) -> UnitStats:
	var piece := get_piece(from)
	assert(piece, "No piece to move at %s!" % from)

	var captured := get_piece(to)
	set_piece(from, null)
	set_piece(to, piece)
	return captured


func is_empty(tile: Vector2i) -> bool:
	return get_piece(tile) == null


func is_enemy(tile: Vector2i, team: UnitStats.Team) -> bool:
	var piece := get_piece(tile)
	return piece != null and piece.team != team
