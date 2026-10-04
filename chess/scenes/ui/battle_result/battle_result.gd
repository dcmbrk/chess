class_name BattleResult
extends CanvasLayer

@export var player_team := UnitStats.Team.WHITE

@onready var title: Label = %Title
@onready var play_again_button: Button = %PlayAgainButton


func _ready() -> void:
	hide()
	play_again_button.pressed.connect(_on_play_again_pressed)


func show_result(result: GameRules.Result) -> void:
	title.text = get_result_text(result, player_team)
	show()


static func get_result_text(result: GameRules.Result, team: UnitStats.Team) -> String:
	match result:
		GameRules.Result.DRAW:
			return "Draw!"
		GameRules.Result.WHITE_WINS:
			return "You win!" if team == UnitStats.Team.WHITE else "You lose!"
		GameRules.Result.BLACK_WINS:
			return "You win!" if team == UnitStats.Team.BLACK else "You lose!"
	
	return ""


func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()
