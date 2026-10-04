extends GutTest

const ARENA = preload("res://scenes/arena/arena.tscn")
const Team := UnitStats.Team
const Result := GameRules.Result


func test_result_text_for_white_player() -> void:
	assert_eq(BattleResult.get_result_text(Result.WHITE_WINS, Team.WHITE), "You win!")
	assert_eq(BattleResult.get_result_text(Result.BLACK_WINS, Team.WHITE), "You lose!")
	assert_eq(BattleResult.get_result_text(Result.DRAW, Team.WHITE), "Draw!")


func test_result_text_for_black_player() -> void:
	assert_eq(BattleResult.get_result_text(Result.BLACK_WINS, Team.BLACK), "You win!")
	assert_eq(BattleResult.get_result_text(Result.WHITE_WINS, Team.BLACK), "You lose!")


func test_popup_is_hidden_during_battle() -> void:
	var arena: Arena = ARENA.instantiate()
	add_child_autofree(arena)

	assert_false(arena.battle_result.visible)


func test_popup_shows_when_battle_ends() -> void:
	var arena: Arena = ARENA.instantiate()
	add_child_autofree(arena)
	var grid := arena.board.unit_grid
	arena.preparation.start_battle()

	for tile: Vector2i in grid.units:
		var unit := grid.units[tile] as Unit
		if unit and unit.stats.team == Team.BLACK:
			grid.remove_unit(tile)
			unit.free()
	arena.turn_manager.end_turn(grid.to_board_state())

	assert_true(arena.battle_result.visible)
	assert_eq(arena.battle_result.title.text, "You win!")
