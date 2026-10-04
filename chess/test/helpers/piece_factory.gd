class_name PieceFactory
extends RefCounted


static func make(type: UnitStats.Type, team := UnitStats.Team.WHITE) -> UnitStats:
	var piece := UnitStats.new()
	piece.type = type
	piece.team = team
	return piece


static func board_with(pieces: Dictionary, size := Vector2i(5, 5)) -> BoardState:
	var board := BoardState.new(size)
	for tile: Vector2i in pieces:
		board.set_piece(tile, pieces[tile])
	return board
