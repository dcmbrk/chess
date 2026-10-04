extends GutTest

const UNIT = preload("res://scenes/unit/unit.tscn")
const WHITE_PAWN = preload("res://data/pieces/white_pawn.tres")

var arena: Arena
var board: PlayArea
var grid: UnitGrid
var unit_mover: UnitMover
var turn_manager: TurnManager


func before_each() -> void:
	arena = ArenaHelper.create_arena(self)
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	board = arena.get_node("Board")
	grid = board.unit_grid
	unit_mover = arena.unit_mover
	turn_manager = arena.turn_manager
	arena.preparation.start_battle()


func _place_unit(tile: Vector2i, stats: UnitStats) -> Unit:
	var unit: Unit = UNIT.instantiate()
	grid.add_child(unit)
	unit.stats = stats
	unit.global_position = board.get_global_from_tile(tile)
	grid.add_unit(tile, unit)
	unit_mover.setup_unit(unit)
	return unit


func test_units_placed_in_scene_are_registered_in_grid() -> void:
	assert_eq(grid.units[Vector2i(1, 1)], arena.get_node("Board/BlackPawn1"))


func test_battle_starts_with_white_after_go() -> void:
	assert_true(turn_manager.active)
	assert_eq(turn_manager.current_team, UnitStats.Team.WHITE)


func test_legal_move_moves_unit_and_ends_turn() -> void:
	var pawn: Unit = grid.units[Vector2i(0, 4)]
	
	var moved := unit_mover.perform_board_move(pawn, Vector2i(0, 4), Vector2i(0, 3))
	
	assert_true(moved)
	assert_null(grid.units[Vector2i(0, 4)])
	assert_eq(grid.units[Vector2i(0, 3)], pawn)
	assert_eq(pawn.global_position, board.get_global_from_tile(Vector2i(0, 3)))
	assert_eq(turn_manager.current_team, UnitStats.Team.BLACK)


func test_illegal_move_changes_nothing() -> void:
	var pawn: Unit = grid.units[Vector2i(0, 4)]
	
	var moved := unit_mover.perform_board_move(pawn, Vector2i(0, 4), Vector2i(0, 2))
	
	assert_false(moved)
	assert_eq(grid.units[Vector2i(0, 4)], pawn)
	assert_null(grid.units[Vector2i(0, 2)])
	assert_eq(turn_manager.current_team, UnitStats.Team.WHITE)


func test_cannot_move_on_opponents_turn() -> void:
	var black_pawn: Unit = grid.units[Vector2i(1, 1)]
	
	assert_false(unit_mover.perform_board_move(black_pawn, Vector2i(1, 1), Vector2i(1, 2)))
	assert_eq(grid.units[Vector2i(1, 1)], black_pawn)


func test_capture_removes_enemy_unit() -> void:
	var white_pawn := _place_unit(Vector2i(2, 2), WHITE_PAWN)
	var victim: Unit = grid.units[Vector2i(1, 1)]
	watch_signals(unit_mover)
	
	var moved := unit_mover.perform_board_move(white_pawn, Vector2i(2, 2), Vector2i(1, 1))
	
	assert_true(moved)
	assert_eq(grid.units[Vector2i(1, 1)], white_pawn)
	assert_true(victim.is_queued_for_deletion())
	assert_signal_emitted_with_parameters(unit_mover, "unit_captured", [victim])


func test_move_works_when_unit_was_already_removed_by_drag() -> void:
	var pawn: Unit = grid.units[Vector2i(0, 4)]
	grid.remove_unit(Vector2i(0, 4))
	
	assert_true(unit_mover.perform_board_move(pawn, Vector2i(0, 4), Vector2i(0, 3)))
	assert_eq(grid.units[Vector2i(0, 3)], pawn)


func test_turns_alternate_between_players() -> void:
	var white: Unit = grid.units[Vector2i(0, 4)]
	var black: Unit = grid.units[Vector2i(3, 1)]
	
	assert_true(unit_mover.perform_board_move(white, Vector2i(0, 4), Vector2i(0, 3)))
	assert_false(unit_mover.perform_board_move(white, Vector2i(0, 3), Vector2i(0, 2)), "white can't move twice")
	assert_true(unit_mover.perform_board_move(black, Vector2i(3, 1), Vector2i(3, 2)))
	assert_true(unit_mover.perform_board_move(white, Vector2i(0, 3), Vector2i(0, 2)))
