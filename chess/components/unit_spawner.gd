class_name UnitSpawner
extends Node

signal unit_spawned(unit: Unit)

const UNIT = preload("res://scenes/unit/unit.tscn")

@export var bench: PlayArea
@export var game_area: PlayArea

#func _ready() -> void:
	#var pawn := preload("res://data/pieces/white_pawn.tres")
	#var tween = create_tween()
	#
	#for i in 15:
		#tween.tween_callback(spawn_unit.bind(pawn))
		#tween.tween_interval(0.5)


func _get_first_available_area() -> PlayArea:
	if not bench.unit_grid.is_grid_full():
		return bench
	elif not game_area.unit_grid.is_grid_full():
		return game_area
	
	return null


func spawn_unit(unit: UnitStats) -> void:
	var area := _get_first_available_area()
	assert(area, "No available space to add unit to!")
	spawn_unit_at(unit, area, area.unit_grid.get_first_empty_tile())


func spawn_unit_at(unit: UnitStats, area: PlayArea, tile: Vector2i) -> void:
	assert(not area.unit_grid.is_tile_occupied(tile), "Tile %s is already occupied!" % tile)
	
	var new_unit := UNIT.instantiate()
	area.unit_grid.add_child(new_unit)
	area.unit_grid.add_unit(tile, new_unit)
	new_unit.global_position = area.get_global_from_tile(tile)
	new_unit.stats = unit
	unit_spawned.emit(new_unit)
