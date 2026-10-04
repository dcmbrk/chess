## Before a battle the player places their pieces in their own rows
## (the bottom [member player_rows] of the board), up to [member max_pieces].
class_name PreparationPhase
extends Node

signal started
signal pieces_changed(count: int, max_count: int)
signal battle_started

@export var board: PlayArea
@export var turn_manager: TurnManager
@export var player_team := UnitStats.Team.WHITE
@export var player_rows := 2
@export var max_pieces := 3

var active := false


func _ready() -> void:
	board.unit_grid.unit_grid_changed.connect(_on_unit_grid_changed)


func start() -> void:
	active = true
	started.emit()
	_on_unit_grid_changed()


func is_in_player_zone(tile: Vector2i) -> bool:
	return board.is_tile_in_bounds(tile) and tile.y >= board.unit_grid.size.y - player_rows


func count_player_pieces(ignored: Unit = null) -> int:
	var count := 0

	for unit in board.unit_grid.get_all_units():
		if unit != ignored and unit.stats.team == player_team:
			count += 1

	return count


## Whether [param unit] may be dropped. [param swapped] is the unit already on
## the target tile, which will take the dragged unit's old place.
func can_drop(unit: Unit, from_board: bool, to_board: bool, to_tile: Vector2i, swapped: Unit) -> bool:
	if unit.stats.team != player_team:
		return false
	if swapped and swapped.stats.team != player_team:
		return false
	if to_board and not is_in_player_zone(to_tile):
		return false
	if to_board and board.unit_grid.forbidden_tiles.get(to_tile, -1) == player_team:
		return false

	var count_after := count_player_pieces(unit)
	if to_board:
		count_after += 1
	if swapped and to_board:
		count_after -= 1
	if swapped and from_board:
		count_after += 1

	return count_after <= max_pieces


func can_start_battle() -> bool:
	return active and count_player_pieces() > 0


func start_battle() -> void:
	assert(can_start_battle(), "Can't start the battle yet!")
	active = false
	battle_started.emit()
	turn_manager.start_battle(board.unit_grid.to_board_state())


func _on_unit_grid_changed() -> void:
	if active:
		pieces_changed.emit(count_player_pieces(), max_pieces)
