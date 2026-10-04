extends GutTest

const Outcome := GameRules.Outcome


func test_win_matches_moodboard_example() -> void:
	# Win $2 + 2 captures $2 + $5 owned -> $1 interest = $5.
	var rewards := BattleRewards.calculate(Outcome.WIN, 2, 5)
	
	assert_eq(rewards.win, 2)
	assert_eq(rewards.captures, 2)
	assert_eq(rewards.interest, 1)
	assert_eq(rewards.total, 5)


func test_interest_rounds_down() -> void:
	assert_eq(BattleRewards.calculate(Outcome.WIN, 0, 4).interest, 0)
	assert_eq(BattleRewards.calculate(Outcome.WIN, 0, 9).interest, 1)
	assert_eq(BattleRewards.calculate(Outcome.WIN, 0, 10).interest, 2)


func test_interest_is_capped() -> void:
	assert_eq(BattleRewards.calculate(Outcome.WIN, 0, 100).interest, BattleRewards.MAX_INTEREST)


func test_draw_has_no_win_reward() -> void:
	var rewards := BattleRewards.calculate(Outcome.DRAW, 3, 10)
	
	assert_eq(rewards.win, 0)
	assert_eq(rewards.captures, 3)
	assert_eq(rewards.interest, 2)


func test_loss_earns_nothing() -> void:
	assert_eq(BattleRewards.calculate(Outcome.LOSS, 3, 25).total, 0)
