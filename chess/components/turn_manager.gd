class_name TurnManager
extends Node

signal turn_started(team: UnitStats.Team)
## Emitted when [param team] has no legal move and has to pass.
signal turn_skipped(team: UnitStats.Team)
signal battle_ended(result: GameRules.Result)

@export var starting_team := UnitStats.Team.WHITE

var current_team: UnitStats.Team
var active := false
var result := GameRules.Result.ONGOING

var _needs_king: Dictionary = {}


func start_battle(board: BoardState) -> void:
	active = true
	result = GameRules.Result.ONGOING
	_needs_king = {
		UnitStats.Team.WHITE: GameRules.has_king(board, UnitStats.Team.WHITE),
		UnitStats.Team.BLACK: GameRules.has_king(board, UnitStats.Team.BLACK),
	}
	_give_turn(starting_team, board)


## Call after a move with the resulting board.
func end_turn(board: BoardState) -> void:
	assert(active, "Can't end a turn outside of a battle!")
	_give_turn(UnitStats.get_opponent(current_team), board)


func can_move(piece: UnitStats) -> bool:
	return active and piece != null and piece.team == current_team


func is_legal_move(board: BoardState, from: Vector2i, to: Vector2i) -> bool:
	return can_move(board.get_piece(from)) and to in MoveRules.get_legal_moves(board, from)


func _give_turn(team: UnitStats.Team, board: BoardState) -> void:
	var new_result := GameRules.get_result(board, _needs_king)
	if new_result != GameRules.Result.ONGOING:
		_end_battle(new_result)
		return

	var other := UnitStats.get_opponent(team)
	if not GameRules.has_legal_moves(board, team):
		if not GameRules.has_legal_moves(board, other):
			_end_battle(GameRules.Result.DRAW)
			return
		turn_skipped.emit(team)
		team = other

	current_team = team
	turn_started.emit(current_team)


func _end_battle(new_result: GameRules.Result) -> void:
	active = false
	result = new_result
	battle_ended.emit(result)
