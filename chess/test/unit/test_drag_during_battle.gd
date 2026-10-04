extends GutTest

var arena: Arena
var grid: UnitGrid
var pawn: Unit
var knight: Unit
var black_pawn: Unit


func before_each() -> void:
	arena = ArenaHelper.create_arena(self)
	arena.get_node("EnemyController").think_delay = 0.0
	grid = arena.board.unit_grid
	pawn = ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	knight = arena.get_node("Bench").unit_grid.units[Vector2i(0, 1)]
	black_pawn = grid.units[Vector2i(1, 1)]


func test_holding_a_piece_during_enemy_turn_does_not_skip_player_turns() -> void:
	arena.preparation.start_battle()
	arena.unit_mover.perform_board_move(pawn, Vector2i(0, 4), Vector2i(0, 3))
	
	# The player picks the pawn up while the enemy is thinking.
	pawn.drag_and_drop.drag_started.emit()
	await wait_process_frames(10)
	
	assert_true(arena.turn_manager.active, "battle should still be running")
	assert_eq(arena.turn_manager.current_team, UnitStats.Team.WHITE)
	assert_eq(grid.units[Vector2i(0, 3)], pawn, "a held piece stays on the board")


func test_canceling_a_drag_during_battle_keeps_the_unit_in_place() -> void:
	arena.preparation.start_battle()
	
	pawn.drag_and_drop.drag_started.emit()
	pawn.drag_and_drop.drag_canceled.emit(pawn.global_position)
	
	assert_eq(grid.units[Vector2i(0, 4)], pawn)


# --- Who can be dragged ---

func test_during_preparation_only_player_pieces_can_be_dragged() -> void:
	assert_true(pawn.drag_and_drop.enabled)
	assert_true(knight.drag_and_drop.enabled)
	assert_false(black_pawn.drag_and_drop.enabled)


func test_player_pieces_can_be_dragged_on_player_turn() -> void:
	arena.preparation.start_battle()
	
	assert_true(pawn.drag_and_drop.enabled)
	assert_false(black_pawn.drag_and_drop.enabled)


func test_nothing_can_be_dragged_on_enemy_turn() -> void:
	arena.preparation.start_battle()
	
	arena.unit_mover.perform_board_move(pawn, Vector2i(0, 4), Vector2i(0, 3))
	
	assert_false(pawn.drag_and_drop.enabled)
	assert_false(knight.drag_and_drop.enabled)


func test_player_can_drag_again_after_enemy_moved() -> void:
	arena.preparation.start_battle()
	arena.unit_mover.perform_board_move(pawn, Vector2i(0, 4), Vector2i(0, 3))
	
	await wait_process_frames(10)
	
	assert_eq(arena.turn_manager.current_team, UnitStats.Team.WHITE)
	assert_true(pawn.drag_and_drop.enabled)


func test_nothing_can_be_dragged_after_battle_ended() -> void:
	arena.preparation.start_battle()
	for tile in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]:
		var unit: Unit = grid.units[tile]
		grid.remove_unit(tile)
		unit.free()
	
	arena.turn_manager.end_turn(grid.to_board_state())
	
	assert_false(arena.turn_manager.active)
	assert_false(pawn.drag_and_drop.enabled)
