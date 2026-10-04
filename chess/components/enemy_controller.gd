class_name EnemyController
extends Node

@export var team := UnitStats.Team.BLACK
@export_range(1, 4) var search_depth := 2
@export var think_delay := 0.5
@export var board: PlayArea
@export var turn_manager: TurnManager
@export var unit_mover: UnitMover


func _ready() -> void:
	turn_manager.turn_started.connect(_on_turn_started)


func play_turn() -> void:
	var board_state := board.unit_grid.to_board_state()
	var move := ChessAI.choose_move(board_state, team, search_depth, RunState.rng)

	# TurnManager skips the turn of a team without legal moves.
	if not move:
		return

	var unit: Unit = board.unit_grid.units[move.from]
	unit_mover.perform_board_move(unit, move.from, move.to)


func _on_turn_started(current_team: UnitStats.Team) -> void:
	if current_team != team:
		return

	# Not process_always: the enemy waits while the game is paused.
	await get_tree().create_timer(Settings.get_enemy_delay(think_delay), false).timeout

	if turn_manager.active and turn_manager.current_team == team:
		play_turn()
