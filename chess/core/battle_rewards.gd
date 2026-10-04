## Money earned at the end of a battle.
## A loss earns nothing, a draw earns everything except the win reward.
class_name BattleRewards
extends RefCounted

const WIN_REWARD := 2
const CAPTURE_REWARD := 1
## $1 of interest for every INTEREST_STEP dollars owned, up to MAX_INTEREST.
const INTEREST_STEP := 5
const MAX_INTEREST := 5

var win := 0
var captures := 0
var interest := 0
var total: int:
	get:
		return win + captures + interest


static func calculate(outcome: GameRules.Outcome, captured_count: int, money: int) -> BattleRewards:
	var rewards := BattleRewards.new()

	if outcome == GameRules.Outcome.LOSS:
		return rewards

	if outcome == GameRules.Outcome.WIN:
		rewards.win = WIN_REWARD
	rewards.captures = captured_count * CAPTURE_REWARD
	@warning_ignore("integer_division")
	rewards.interest = mini(money / INTEREST_STEP, MAX_INTEREST)
	return rewards
