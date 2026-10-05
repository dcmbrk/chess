extends GutTest

const Team := UnitStats.Team

var arena: Arena


func before_each() -> void:
	arena = ArenaHelper.create_arena(self)
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(4, 4))


func after_all() -> void:
	RunState.reset()


# --- Wait ---

func test_wait_skips_the_player_turn() -> void:
	arena.preparation.start_battle()
	
	assert_true(arena.wait())
	
	assert_eq(arena.turn_manager.current_team, Team.BLACK)
	assert_eq(arena.waits_left, Arena.MAX_WAITS - 1)


func test_wait_is_limited_per_battle() -> void:
	arena.preparation.start_battle()
	for i in Arena.MAX_WAITS:
		assert_true(arena.wait())
		arena.unit_mover.end_turn() # the enemy's turn
	
	assert_false(arena.can_wait())
	assert_false(arena.wait())


func test_cannot_wait_on_the_enemy_turn_or_before_the_battle() -> void:
	assert_false(arena.can_wait(), "preparing")
	arena.preparation.start_battle()
	arena.wait()
	
	assert_false(arena.can_wait(), "enemy turn")


# --- Crumble ---

func test_countdown_runs_on_every_turn() -> void:
	arena.preparation.start_battle()
	var crumbler := arena.crumbler
	
	arena.unit_mover.end_turn()
	arena.unit_mover.end_turn()
	
	assert_eq(crumbler.get_turns_left(), crumbler.turns_before_crumbling - 2)
	assert_false(crumbler.is_crumbling())
	assert_true(arena.board.unit_grid.holes.is_empty())


func test_tiles_fall_once_the_countdown_is_over() -> void:
	arena.preparation.start_battle()
	var crumbler := arena.crumbler
	crumbler.turns_played = crumbler.turns_before_crumbling
	
	arena.unit_mover.end_turn()
	
	assert_true(crumbler.is_crumbling())
	assert_eq(arena.board.unit_grid.holes.size(), 1)


func test_outer_ring_falls_first() -> void:
	for i in 16:
		var tile := arena.crumbler.crumble_next_tile()
		assert_true(tile.x == 0 or tile.y == 0 or tile.x == 4 or tile.y == 4, "%s is on the outer ring" % tile)
	var inner := arena.crumbler.crumble_next_tile()
	
	assert_true(Rect2i(1, 1, 3, 3).has_point(inner))


func test_a_piece_on_a_falling_tile_falls_too() -> void:
	var grid := arena.board.unit_grid
	# Fill the outer ring except the white pawn's tile with holes.
	for x in 5:
		for y in 5:
			var tile := Vector2i(x, y)
			if (x == 0 or y == 0 or x == 4 or y == 4) and tile != Vector2i(4, 4):
				grid.holes[tile] = true
	var pawn: Unit = grid.units[Vector2i(4, 4)]
	
	arena.crumbler.crumble_next_tile()
	
	assert_true(pawn.is_queued_for_deletion())
	assert_null(grid.units[Vector2i(4, 4)])
	assert_has(RunState.graveyard, preload("res://data/pieces/white_pawn.tres"))


# --- Battle bar ---

func test_battle_bar_shows_during_the_battle() -> void:
	assert_false(arena.battle_bar.visible)
	
	arena.preparation.start_battle()
	
	assert_true(arena.battle_bar.visible)
	assert_eq(arena.battle_bar.turn_label.text, "Your turn!")
	assert_eq(arena.battle_bar.wait_count.text, "3/3")


func test_battle_bar_follows_turns_and_waits() -> void:
	arena.preparation.start_battle()
	
	arena.battle_bar.wait_button.pressed.emit()
	
	assert_eq(arena.battle_bar.turn_label.text, "Enemy turn")
	assert_eq(arena.battle_bar.wait_count.text, "2/3")
	assert_true(arena.battle_bar.wait_button.disabled)


func test_crumble_dots() -> void:
	assert_eq(BattleBar.get_dot_count(16), 5)
	assert_eq(BattleBar.get_dot_count(3), 2)
	assert_eq(BattleBar.get_dot_count(0), 0)
	
	arena.battle_bar.set_countdown(0)
	assert_eq(arena.battle_bar.crumble_label.text, "Crumbling!")
