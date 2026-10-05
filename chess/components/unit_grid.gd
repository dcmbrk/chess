class_name UnitGrid
extends Node2D

signal unit_grid_changed

@export var size: Vector2i

var units: Dictionary
## CURSED tiles: tile -> the UnitStats.Team that may not enter it.
var forbidden_tiles: Dictionary[Vector2i, int] = {}
## STASIS: units on these tiles can't move and can't be captured.
var frozen_tiles: Dictionary[Vector2i, bool] = {}
## Special tiles placed by the player. Their effects live in TileEffects.
var special_tiles: Dictionary[Vector2i, SpecialTileData] = {}
## Crumbled tiles: nobody can enter them.
var holes: Dictionary[Vector2i, bool] = {}


func _ready() -> void:
	for i in size.x:
		for j in size.y:
			units[Vector2i(i, j)] = null


func add_unit(tile: Vector2i, unit: Node) -> void:
	units[tile] = unit
	unit_grid_changed.emit()


func remove_unit(tile: Vector2i) -> void:
	var unit := units[tile] as Node
	
	if not unit:
		return
	
	units[tile] = null
	unit_grid_changed.emit()


func is_tile_occupied(tile: Vector2i) -> bool:
	return units[tile] != null


func is_grid_full() -> bool:
	return units.keys().all(is_tile_occupied)


func get_first_empty_tile() -> Vector2i:
	for tile in units:
		if not is_tile_occupied(tile):
			return tile

	# no empty tile
	return Vector2i(-1, -1)


func get_all_units() -> Array[Unit]:
	var unit_array: Array[Unit] = []
	
	for unit: Unit in units.values():
		if unit:
			unit_array.append(unit)

	return unit_array


func to_board_state() -> BoardState:
	var board := BoardState.new(size)
	board.forbidden_tiles = forbidden_tiles.duplicate()
	board.frozen_tiles = frozen_tiles.duplicate()
	board.holes = holes.duplicate()

	for tile: Vector2i in units:
		var unit := units[tile] as Unit
		if unit and unit.stats:
			board.set_piece(tile, unit.stats)
			if unit.is_protected:
				board.protected_tiles[tile] = unit.stats.team
			if unit.is_trapped:
				board.frozen_tiles[tile] = true

	return board
