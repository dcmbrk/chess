extends GutTest

const UNIT = preload("res://scenes/unit/unit.tscn")
const BLACK_PAWN = preload("res://data/pieces/black_pawn.tres")

var arena: Arena
var board: PlayArea
var highlighter: MoveHighlighter
var hints: TileMapLayer


func before_each() -> void:
	arena = ArenaHelper.create_arena(self)
	board = arena.get_node("Board")
	highlighter = arena.get_node("MoveHighlighter")
	hints = board.get_node("MoveHints")


func _place_unit(tile: Vector2i, stats: UnitStats) -> Unit:
	var unit: Unit = UNIT.instantiate()
	board.unit_grid.add_child(unit)
	unit.stats = stats
	unit.global_position = board.get_global_from_tile(tile)
	board.unit_grid.add_unit(tile, unit)
	highlighter.setup_unit(unit)
	return unit


func test_show_moves_highlights_legal_tiles() -> void:
	var pawn := _place_unit(Vector2i(2, 2), BLACK_PAWN)

	highlighter.show_moves(pawn)

	assert_eq(hints.get_used_cells(), [Vector2i(2, 3)] as Array[Vector2i])


func test_clear_removes_hints() -> void:
	var pawn := _place_unit(Vector2i(2, 2), BLACK_PAWN)
	highlighter.show_moves(pawn)

	highlighter.clear()

	assert_eq(hints.get_used_cells().size(), 0)


func test_unit_outside_board_shows_nothing() -> void:
	var pawn := _place_unit(Vector2i(2, 2), BLACK_PAWN)
	pawn.global_position = board.get_global_from_tile(Vector2i(-3, 0))

	highlighter.show_moves(pawn)

	assert_eq(hints.get_used_cells().size(), 0)


func test_hover_shows_moves() -> void:
	var pawn := _place_unit(Vector2i(2, 2), BLACK_PAWN)
	
	pawn.mouse_entered.emit()
	
	assert_eq(hints.get_used_cells(), [Vector2i(2, 3)] as Array[Vector2i])


func test_unhover_clears_moves() -> void:
	var pawn := _place_unit(Vector2i(2, 2), BLACK_PAWN)
	pawn.mouse_entered.emit()
	
	pawn.mouse_exited.emit()
	
	assert_eq(hints.get_used_cells().size(), 0)


func test_hover_is_ignored_while_another_unit_is_dragged() -> void:
	var dragged := _place_unit(Vector2i(2, 2), BLACK_PAWN)
	var other := _place_unit(Vector2i(0, 0), BLACK_PAWN)
	dragged.add_to_group("dragging")
	highlighter.show_moves(dragged)
	
	other.mouse_entered.emit()
	other.mouse_exited.emit()
	
	assert_eq(hints.get_used_cells(), [Vector2i(2, 3)] as Array[Vector2i])
