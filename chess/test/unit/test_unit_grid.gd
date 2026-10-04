extends GutTest

const UNIT = preload("res://scenes/unit/unit.tscn")
const WHITE_KNIGHT = preload("res://data/pieces/white_knight.tres")
const BLACK_PAWN = preload("res://data/pieces/black_pawn.tres")

var grid: UnitGrid


func before_each() -> void:
	grid = UnitGrid.new()
	grid.size = Vector2i(5, 5)
	add_child_autofree(grid)


func _add_unit(tile: Vector2i, stats: UnitStats) -> Unit:
	var unit: Unit = UNIT.instantiate()
	grid.add_child(unit)
	unit.stats = stats
	grid.add_unit(tile, unit)
	return unit


func test_to_board_state_copies_size() -> void:
	assert_eq(grid.to_board_state().size, Vector2i(5, 5))


func test_to_board_state_copies_units() -> void:
	_add_unit(Vector2i(1, 4), WHITE_KNIGHT)
	_add_unit(Vector2i(3, 0), BLACK_PAWN)

	var board := grid.to_board_state()

	assert_eq(board.get_piece(Vector2i(1, 4)), WHITE_KNIGHT)
	assert_eq(board.get_piece(Vector2i(3, 0)), BLACK_PAWN)
	assert_true(board.is_empty(Vector2i(2, 2)))


func test_piece_resources_have_correct_type_and_team() -> void:
	assert_eq(WHITE_KNIGHT.type, UnitStats.Type.KNIGHT)
	assert_eq(WHITE_KNIGHT.team, UnitStats.Team.WHITE)
	assert_eq(BLACK_PAWN.type, UnitStats.Type.PAWN)
	assert_eq(BLACK_PAWN.team, UnitStats.Team.BLACK)


func test_get_opponent() -> void:
	assert_eq(UnitStats.get_opponent(UnitStats.Team.WHITE), UnitStats.Team.BLACK)
	assert_eq(UnitStats.get_opponent(UnitStats.Team.BLACK), UnitStats.Team.WHITE)
