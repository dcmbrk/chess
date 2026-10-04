extends GutTest

const ARENA = preload("res://scenes/arena/arena.tscn")
const UNIT = preload("res://scenes/unit/unit.tscn")
const BLACK_PAWN = preload("res://data/pieces/black_pawn.tres")

# Arena layout: white pawn on (0, 4), black pawns on (1..3, 1), white knight on the bench.
var arena: Arena
var preparation: PreparationPhase
var grid: UnitGrid
var white_pawn: Unit
var bench_knight: Unit


func before_each() -> void:
	arena = ARENA.instantiate()
	add_child_autofree(arena)
	preparation = arena.preparation
	grid = arena.board.unit_grid
	white_pawn = grid.units[Vector2i(0, 4)]
	bench_knight = arena.get_node("Bench/Piece")


func _place_unit(tile: Vector2i, stats: UnitStats) -> Unit:
	var unit: Unit = UNIT.instantiate()
	grid.add_child(unit)
	unit.stats = stats
	grid.add_unit(tile, unit)
	return unit


func test_arena_starts_in_preparation() -> void:
	assert_true(preparation.active)
	assert_false(arena.turn_manager.active)
	assert_true(arena.prep_panel.visible)
	assert_true(arena.enemy_zone_overlay.visible)
	assert_eq(arena.prep_panel.pieces_label.text, "Pieces 1/3")


func test_player_zone_is_the_bottom_two_rows() -> void:
	assert_true(preparation.is_in_player_zone(Vector2i(0, 4)))
	assert_true(preparation.is_in_player_zone(Vector2i(4, 3)))
	assert_false(preparation.is_in_player_zone(Vector2i(2, 2)))
	assert_false(preparation.is_in_player_zone(Vector2i(5, 4)), "out of bounds")


func test_count_player_pieces() -> void:
	assert_eq(preparation.count_player_pieces(), 1)
	assert_eq(preparation.count_player_pieces(white_pawn), 0)


# --- can_drop ---

func test_can_place_from_bench_into_player_zone() -> void:
	assert_true(preparation.can_drop(bench_knight, false, true, Vector2i(2, 3), null))


func test_cannot_place_into_enemy_zone() -> void:
	assert_false(preparation.can_drop(bench_knight, false, true, Vector2i(2, 2), null))


func test_cannot_move_enemy_pieces() -> void:
	var black_pawn: Unit = grid.units[Vector2i(1, 1)]
	assert_false(preparation.can_drop(black_pawn, true, true, Vector2i(1, 4), null))


func test_cannot_swap_with_enemy_piece() -> void:
	var black_pawn := _place_unit(Vector2i(2, 4), BLACK_PAWN)
	assert_false(preparation.can_drop(bench_knight, false, true, Vector2i(2, 4), black_pawn))


func test_cannot_exceed_max_pieces() -> void:
	preparation.max_pieces = 1
	assert_false(preparation.can_drop(bench_knight, false, true, Vector2i(2, 3), null))


func test_swapping_at_max_pieces_is_allowed() -> void:
	preparation.max_pieces = 1
	assert_true(preparation.can_drop(bench_knight, false, true, Vector2i(0, 4), white_pawn), "bench -> board swap")
	assert_true(preparation.can_drop(white_pawn, true, false, Vector2i(0, 0), bench_knight), "board -> bench swap")


func test_moving_on_board_and_back_to_bench_at_max_is_allowed() -> void:
	preparation.max_pieces = 1
	grid.remove_unit(Vector2i(0, 4)) # UnitMover removes the unit while it is dragged.
	assert_true(preparation.can_drop(white_pawn, true, true, Vector2i(3, 3), null))
	assert_true(preparation.can_drop(white_pawn, true, false, Vector2i(0, 1), null))


# --- Pieces counter ---

func test_pieces_changed_is_emitted_when_grid_changes() -> void:
	watch_signals(preparation)

	grid.add_unit(Vector2i(2, 3), bench_knight)

	assert_signal_emitted_with_parameters(preparation, "pieces_changed", [2, 3])
	assert_eq(arena.prep_panel.pieces_label.text, "Pieces 2/3")


func test_cannot_start_battle_without_pieces() -> void:
	grid.remove_unit(Vector2i(0, 4))

	assert_false(preparation.can_start_battle())
	assert_true(arena.prep_panel.go_button.disabled)


# --- Start battle ---

func test_start_battle_ends_preparation() -> void:
	watch_signals(preparation)

	preparation.start_battle()

	assert_false(preparation.active)
	assert_true(arena.turn_manager.active)
	assert_eq(arena.turn_manager.current_team, UnitStats.Team.WHITE)
	assert_signal_emitted(preparation, "battle_started")
	assert_false(arena.prep_panel.visible)
	assert_false(arena.enemy_zone_overlay.visible)


func test_go_button_starts_battle() -> void:
	arena.prep_panel.go_button.pressed.emit()

	assert_true(arena.turn_manager.active)


func test_counter_stops_updating_after_battle_started() -> void:
	preparation.start_battle()
	watch_signals(preparation)

	grid.add_unit(Vector2i(2, 3), bench_knight)

	assert_signal_not_emitted(preparation, "pieces_changed")
