class_name UnitMover
extends Node

signal unit_captured(unit: Unit)

@export var play_areas: Array[PlayArea]
@export var board: PlayArea
@export var turn_manager: TurnManager
@export var player_team := UnitStats.Team.WHITE
@export var preparation: PreparationPhase


func _ready() -> void:
	var units := get_tree().get_nodes_in_group("units")
	for unit: Unit in units:
		_register_unit(unit)
		setup_unit(unit)


func setup_unit(unit: Unit) -> void:
	unit.drag_and_drop.drag_started.connect(_on_unit_drag_started.bind(unit))
	unit.drag_and_drop.drag_canceled.connect(_on_unit_drag_canceled.bind(unit))
	unit.drag_and_drop.dropped.connect(_on_unit_dropped.bind(unit))
	


## Moves a unit that is on the board, following the chess rules.
## Returns false (and changes nothing) if the move is illegal.
func perform_board_move(unit: Unit, from: Vector2i, to: Vector2i) -> bool:
	# The unit may already be removed from the grid while it is dragged.
	var board_state := board.unit_grid.to_board_state()
	board_state.set_piece(from, unit.stats)
	
	if not turn_manager.is_legal_move(board_state, from, to):
		return false
	
	if board.unit_grid.units[from] == unit:
		board.unit_grid.remove_unit(from)
	
	var captured := board.unit_grid.units[to] as Unit
	if captured:
		board.unit_grid.remove_unit(to)
		unit_captured.emit(captured)
		captured.queue_free()
	
	_move_unit(unit, board, to)
	turn_manager.end_turn(board.unit_grid.to_board_state())
	return true


func _is_battle_active() -> bool:
	return turn_manager != null and turn_manager.active


func _is_preparing() -> bool:
	return preparation != null and preparation.active


func _register_unit(unit: Unit) -> void:
	var i := _get_play_area_for_position(unit.global_position)
	if i == -1:
		return
	
	var tile := play_areas[i].get_tile_from_global(unit.global_position)
	play_areas[i].unit_grid.add_unit(tile, unit)


func _set_highlighters(enabled: bool) -> void:
	for play_area: PlayArea in play_areas:
		play_area.tile_highlighter.enabled = enabled


func _get_play_area_for_position(global: Vector2) -> int:
	var dropped_area_index := -1
	
	for i in play_areas.size():
		var tile := play_areas[i].get_tile_from_global(global)
		if play_areas[i].is_tile_in_bounds(tile):
			dropped_area_index = i
	
	return dropped_area_index


func _reset_unit_to_starting_position(starting_position: Vector2, unit: Unit) -> void:
	var i := _get_play_area_for_position(starting_position)
	var tile := play_areas[i].get_tile_from_global(starting_position)
	
	unit.reset_after_dragging(starting_position)
	play_areas[i].unit_grid.add_unit(tile, unit)


func _move_unit(unit: Unit, play_area: PlayArea, tile: Vector2i) -> void:
	play_area.unit_grid.add_unit(tile, unit)
	unit.global_position = play_area.get_global_from_tile(tile)
	unit.reparent(play_area.unit_grid)


func _on_unit_drag_started(unit: Unit) -> void:
	_set_highlighters(true)
	
	var i := _get_play_area_for_position(unit.global_position)
	if i > -1:
		var tile := play_areas[i].get_tile_from_global(unit.global_position)
		play_areas[i].unit_grid.remove_unit(tile)


func _on_unit_drag_canceled(starting_position: Vector2, unit: Unit) -> void:
	_set_highlighters(false)
	_reset_unit_to_starting_position(starting_position, unit)


func _on_unit_dropped(starting_position: Vector2, unit: Unit) -> void:
	_set_highlighters(false)

	var old_area_index := _get_play_area_for_position(starting_position)
	var drop_area_index := _get_play_area_for_position(unit.get_global_mouse_position())
	
	if drop_area_index == -1:
		_reset_unit_to_starting_position(starting_position, unit)
		return

	var old_area := play_areas[old_area_index]
	var old_tile := old_area.get_tile_from_global(starting_position)
	var new_area := play_areas[drop_area_index]
	var new_tile := new_area.get_hovered_tile()
	
	if _is_battle_active() and (old_area == board or new_area == board):
		var is_board_move := old_area == board and new_area == board
		var is_player_unit := unit.stats.team == player_team
		if not is_board_move or not is_player_unit or not perform_board_move(unit, old_tile, new_tile):
			_reset_unit_to_starting_position(starting_position, unit)
		return
	
	if _is_preparing() and (old_area == board or new_area == board):
		var swapped := new_area.unit_grid.units[new_tile] as Unit
		if not preparation.can_drop(unit, old_area == board, new_area == board, new_tile, swapped):
			_reset_unit_to_starting_position(starting_position, unit)
			return
	
	if new_area.unit_grid.is_tile_occupied(new_tile):
		var old_unit: Unit = new_area.unit_grid.units[new_tile]
		new_area.unit_grid.remove_unit(new_tile)
		_move_unit(old_unit, old_area, old_tile)
	
	_move_unit(unit, new_area, new_tile)
