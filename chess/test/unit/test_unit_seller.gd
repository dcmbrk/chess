extends GutTest

const WHITE_PAWN = preload("res://data/pieces/white_pawn.tres")
const WHITE_KNIGHT = preload("res://data/pieces/white_knight.tres")

# With RunState.reset() the bench holds a pawn on (0, 0) and a knight on (0, 1).
var arena: Arena
var seller: UnitSeller
var bench: PlayArea
var pawn: Unit
var knight: Unit


func before_each() -> void:
	arena = ArenaHelper.create_arena(self)
	seller = arena.unit_seller
	bench = arena.get_node("Bench")
	pawn = bench.unit_grid.units[Vector2i(0, 0)]
	knight = bench.unit_grid.units[Vector2i(0, 1)]


func after_all() -> void:
	RunState.reset()


# --- Selling ---

func test_sell_from_the_bench() -> void:
	watch_signals(seller)
	
	assert_true(seller.sell(knight))
	
	assert_eq(RunState.money, WHITE_KNIGHT.get_sell_price())
	assert_eq(RunState.pieces, [WHITE_PAWN] as Array[UnitStats])
	assert_null(bench.unit_grid.units[Vector2i(0, 1)])
	assert_true(knight.is_queued_for_deletion())
	assert_signal_emitted_with_parameters(seller, "unit_sold", [knight, 3])


func test_sell_from_the_board_updates_the_counter() -> void:
	ArenaHelper.move_to_board(arena, Vector2i(0, 1), Vector2i(2, 4))
	assert_eq(arena.prep_panel.pieces_label.text, "Pieces 1/3")
	
	assert_true(seller.sell(knight))
	
	assert_null(arena.board.unit_grid.units[Vector2i(2, 4)])
	assert_eq(arena.prep_panel.pieces_label.text, "Pieces 0/3")


func test_cannot_sell_the_last_piece() -> void:
	seller.sell(knight)
	
	assert_false(seller.sell(pawn))
	assert_eq(RunState.pieces.size(), 1)


func test_cannot_sell_enemy_pieces() -> void:
	var black_pawn: Unit = arena.board.unit_grid.units[Vector2i(1, 1)]
	
	assert_false(seller.can_sell(black_pawn))
	assert_false(seller.sell(black_pawn))


func test_cannot_sell_during_battle() -> void:
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	arena.preparation.start_battle()
	
	assert_false(seller.sell(knight))


func test_sells_the_original_piece_of_a_promoted_unit() -> void:
	pawn.promote(preload("res://data/pieces/white_queen.tres"))
	
	assert_true(seller.sell(pawn))
	
	assert_eq(RunState.pieces, [WHITE_KNIGHT] as Array[UnitStats])
	assert_eq(RunState.money, WHITE_PAWN.get_sell_price())


# --- Holding the right mouse button ---

func _right_click(unit: Unit, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = pressed
	if pressed:
		unit.input_event.emit(get_viewport(), event, 0)
	else:
		seller._input(event)


func test_holding_right_click_sells_the_piece() -> void:
	_right_click(knight, true)
	
	seller._process(seller.hold_time / 2)
	assert_false(knight.is_queued_for_deletion(), "not yet")
	assert_ne(knight.modulate, Color.WHITE, "tinted while holding")
	
	seller._process(seller.hold_time / 2)
	
	assert_true(knight.is_queued_for_deletion())
	assert_eq(RunState.pieces, [WHITE_PAWN] as Array[UnitStats])


func test_releasing_right_click_early_does_not_sell() -> void:
	_right_click(knight, true)
	seller._process(seller.hold_time / 2)
	
	_right_click(knight, false)
	seller._process(seller.hold_time)
	
	assert_false(knight.is_queued_for_deletion())
	assert_eq(knight.modulate, Color.WHITE)


func test_leaving_the_piece_cancels_the_sale() -> void:
	_right_click(knight, true)
	
	knight.mouse_exited.emit()
	seller._process(seller.hold_time)
	
	assert_false(knight.is_queued_for_deletion())


func test_left_click_does_not_sell() -> void:
	knight.drag_and_drop._start_dragging()
	
	seller._process(seller.hold_time * 2)
	
	assert_false(knight.is_queued_for_deletion())
	knight.drag_and_drop._cancel_dragging()


func test_cannot_start_selling_a_dragged_piece() -> void:
	knight.drag_and_drop._start_dragging()
	
	_right_click(knight, true)
	seller._process(seller.hold_time)
	
	assert_false(knight.is_queued_for_deletion())
	knight.drag_and_drop._cancel_dragging()


# --- Tooltip ---

func test_tooltip_shows_name_and_how_to_sell_while_preparing() -> void:
	knight.mouse_entered.emit()
	
	assert_true(Tooltip.is_showing())
	assert_eq(Tooltip.title.text, "Knight")
	assert_eq(Tooltip.subtitle.text, "Hold right click: sell +$3")
	knight.mouse_exited.emit()


func test_tooltip_shows_only_the_name_for_enemies() -> void:
	var black_pawn: Unit = arena.board.unit_grid.units[Vector2i(1, 1)]
	
	black_pawn.mouse_entered.emit()
	
	assert_eq(Tooltip.title.text, "Pawn")
	assert_false(Tooltip.subtitle.visible)
	black_pawn.mouse_exited.emit()


func test_tooltip_hides_on_exit() -> void:
	knight.mouse_entered.emit()
	knight.mouse_exited.emit()
	
	assert_false(Tooltip.is_showing())


func test_tooltip_hides_when_the_unit_is_sold() -> void:
	knight.mouse_entered.emit()
	
	seller.sell(knight)
	await wait_process_frames(3)
	
	assert_false(Tooltip.is_showing())
