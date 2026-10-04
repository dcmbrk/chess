## Changes the end of battle rewards.
class_name RewardBonusGambit
extends GambitData

## Extra money when the battle is won.
@export var win_bonus := 0
## Raises the interest limit (BattleRewards.MAX_INTEREST).
@export var interest_cap_bonus := 0


func modify_rewards(rewards: BattleRewards, outcome: GameRules.Outcome, money: int) -> void:
	if outcome == GameRules.Outcome.WIN:
		rewards.win += win_bonus
	
	if interest_cap_bonus > 0 and outcome != GameRules.Outcome.LOSS:
		@warning_ignore("integer_division")
		var interest := money / BattleRewards.INTEREST_STEP
		rewards.interest = mini(interest, BattleRewards.MAX_INTEREST + interest_cap_bonus)
