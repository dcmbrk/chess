## The special rule of a stage's boss battle. Subclasses override the hooks they need.
class_name BossData
extends Resource

@export var display_name := ""
@export_multiline var description := ""


## Called once the enemies and the player's pieces are spawned, before the preparation starts.
func setup_battle(_arena: Arena) -> void:
	pass


func on_unit_captured(_arena: Arena, _unit: Unit, _by: Unit) -> void:
	pass
