class_name ProgressLabel
extends Label


func _ready() -> void:
	text = get_progress_text(RunState.stage, RunState.game)


static func get_progress_text(stage: int, game: int) -> String:
	var progress := "Stage %d/%d  Game %d/%d" % [stage, RunState.STAGE_COUNT, game, RunState.GAMES_PER_STAGE]
	if game == RunState.GAMES_PER_STAGE:
		progress += "  BOSS"
	return progress
