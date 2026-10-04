extends Control



func _on_play_pressed() -> void:
	RunState.reset()
	get_tree().change_scene_to_file("res://scenes/piece_wheels/piece_wheels.tscn")
