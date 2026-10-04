class_name BattleResult
extends CanvasLayer

## Emitted after the player pressed the button (and the money was collected).
signal closed

var outcome: GameRules.Outcome
var rewards: BattleRewards

@onready var title: Label = %Title
@onready var rewards_grid: GridContainer = %RewardsGrid
@onready var win_amount: Label = %WinAmount
@onready var captures_label: Label = %CapturesLabel
@onready var captures_amount: Label = %CapturesAmount
@onready var interest_amount: Label = %InterestAmount
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	continue_button.pressed.connect(_on_continue_pressed)


func show_result(battle_outcome: GameRules.Outcome, battle_rewards: BattleRewards, captured_count: int) -> void:
	outcome = battle_outcome
	rewards = battle_rewards
	
	title.text = get_outcome_text(outcome)
	rewards_grid.visible = outcome != GameRules.Outcome.LOSS
	win_amount.text = "$%d" % rewards.win
	captures_label.text = "Captured x%d" % captured_count
	captures_amount.text = "$%d" % rewards.captures
	interest_amount.text = "$%d" % rewards.interest
	
	if outcome == GameRules.Outcome.LOSS:
		continue_button.text = "Try again"
	else:
		continue_button.text = "Get my $%d!!" % rewards.total
	
	show()


static func get_outcome_text(battle_outcome: GameRules.Outcome) -> String:
	match battle_outcome:
		GameRules.Outcome.WIN:
			return "You win!"
		GameRules.Outcome.LOSS:
			return "You lose!"
	
	return "Draw!"


func _on_continue_pressed() -> void:
	if outcome == GameRules.Outcome.LOSS:
		RunState.reset()
	else:
		RunState.add_money(rewards.total)
	
	hide()
	closed.emit()
