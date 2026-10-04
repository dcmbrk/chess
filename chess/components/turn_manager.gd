class_name TurnManager
extends Node

signal turn_started(team: UnitStats.Team)

@export var starting_team := UnitStats.Team.WHITE

var current_team: UnitStats.Team
var active := false


static func get_opponent(team: UnitStats.Team) -> UnitStats.Team:
	return UnitStats.Team.BLACK if team == UnitStats.Team.WHITE else UnitStats.Team.WHITE


func start_battle() -> void:
	active = true
	current_team = starting_team
	turn_started.emit(current_team)


func end_turn() -> void:
	assert(active, "Can't end a turn outside of a battle!")
	current_team = get_opponent(current_team)
	turn_started.emit(current_team)


func can_move(piece: UnitStats) -> bool:
	return active and piece != null and piece.team == current_team


func is_legal_move(board: BoardState, from: Vector2i, to: Vector2i) -> bool:
	return can_move(board.get_piece(from)) and to in MoveRules.get_legal_moves(board, from)
