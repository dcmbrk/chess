## Helpers for tests that use the arena scene.
## The arena gets three black pawns on (1, 1), (2, 1) and (3, 1).
## With RunState.reset(), the bench holds a white pawn on (0, 0) and a white knight on (0, 1).
class_name ArenaHelper
extends RefCounted

const ARENA = preload("res://scenes/arena/arena.tscn")
const UNIT = preload("res://scenes/unit/unit.tscn")
const BLACK_PAWN = preload("res://data/pieces/black_pawn.tres")


static func create_arena(test: GutTest, encounter: EncounterData = null) -> Arena:
	RunState.reset()
	var arena: Arena = ARENA.instantiate()
	arena.encounter = encounter if encounter else three_pawns()
	test.add_child_autofree(arena)
	return arena


static func three_pawns() -> EncounterData:
	var encounter := EncounterData.new()
	for x in [1, 2, 3]:
		encounter.pieces[Vector2i(x, 1)] = BLACK_PAWN
	return encounter


static func move_to_board(arena: Arena, bench_tile: Vector2i, board_tile: Vector2i) -> Unit:
	var unit: Unit = arena.get_node("Bench").unit_grid.units[bench_tile]
	arena.get_node("Bench").unit_grid.remove_unit(bench_tile)
	_put_on_board(arena, unit, board_tile)
	return unit


static func place_unit(arena: Arena, board_tile: Vector2i, stats: UnitStats) -> Unit:
	var unit: Unit = UNIT.instantiate()
	arena.board.unit_grid.add_child(unit)
	unit.stats = stats
	# Connects the unit to every component, like a spawned unit.
	arena.unit_spawner.unit_spawned.emit(unit)
	_put_on_board(arena, unit, board_tile)
	return unit


static func _put_on_board(arena: Arena, unit: Unit, board_tile: Vector2i) -> void:
	unit.reparent(arena.board.unit_grid)
	unit.global_position = arena.board.get_global_from_tile(board_tile)
	arena.board.unit_grid.add_unit(board_tile, unit)
