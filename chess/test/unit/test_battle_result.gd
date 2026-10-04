extends GutTest

const BATTLE_RESULT = preload("res://scenes/ui/battle_result/battle_result.tscn")
const WHITE_PAWN = preload("res://data/pieces/white_pawn.tres")
const Outcome := GameRules.Outcome

var popup: BattleResult


func before_each() -> void:
	RunState.reset()
	popup = BATTLE_RESULT.instantiate()
	add_child_autofree(popup)


func after_all() -> void:
	RunState.reset()


func test_is_hidden_at_start() -> void:
	assert_false(popup.visible)


func test_outcome_text() -> void:
	assert_eq(BattleResult.get_outcome_text(Outcome.WIN), "You win!")
	assert_eq(BattleResult.get_outcome_text(Outcome.LOSS), "You lose!")
	assert_eq(BattleResult.get_outcome_text(Outcome.DRAW), "Draw!")


func test_shows_rewards_after_win() -> void:
	popup.show_result(Outcome.WIN, BattleRewards.calculate(Outcome.WIN, 2, 5), 2)
	
	assert_true(popup.visible)
	assert_eq(popup.title.text, "You win!")
	assert_true(popup.rewards_grid.visible)
	assert_eq(popup.win_amount.text, "$2")
	assert_eq(popup.captures_label.text, "Captured x2")
	assert_eq(popup.captures_amount.text, "$2")
	assert_eq(popup.interest_amount.text, "$1")
	assert_eq(popup.continue_button.text, "Get my $5!!")


func test_hides_rewards_after_loss() -> void:
	popup.show_result(Outcome.LOSS, BattleRewards.calculate(Outcome.LOSS, 2, 5), 2)
	
	assert_eq(popup.title.text, "You lose!")
	assert_false(popup.rewards_grid.visible)
	assert_eq(popup.continue_button.text, "Try again")


func test_continue_collects_money() -> void:
	RunState.add_money(5)
	popup.show_result(Outcome.WIN, BattleRewards.calculate(Outcome.WIN, 2, 5), 2)
	watch_signals(popup)
	
	popup.continue_button.pressed.emit()
	
	assert_eq(RunState.money, 10)
	assert_false(popup.visible)
	assert_signal_emitted(popup, "closed")


func test_continue_after_loss_resets_run() -> void:
	RunState.add_money(7)
	popup.show_result(Outcome.LOSS, BattleRewards.calculate(Outcome.LOSS, 0, 7), 0)
	
	popup.continue_button.pressed.emit()
	
	assert_eq(RunState.money, RunState.STARTING_MONEY)


func test_arena_shows_rewards_when_last_enemy_is_captured() -> void:
	var arena := ArenaHelper.create_arena(self)
	var grid := arena.board.unit_grid
	
	# Leave a single black pawn on (1, 1) and attack it from (2, 2).
	for tile in [Vector2i(2, 1), Vector2i(3, 1)]:
		var unit: Unit = grid.units[tile]
		grid.remove_unit(tile)
		unit.free()
	var attacker := ArenaHelper.place_unit(arena, Vector2i(2, 2), WHITE_PAWN)
	arena.preparation.start_battle()
	
	arena.unit_mover.perform_board_move(attacker, Vector2i(2, 2), Vector2i(1, 1))
	
	assert_eq(arena.captured_enemies, 1)
	assert_true(arena.battle_result.visible)
	assert_eq(arena.battle_result.title.text, "You win!")
	assert_eq(arena.battle_result.continue_button.text, "Get my $3!!")
