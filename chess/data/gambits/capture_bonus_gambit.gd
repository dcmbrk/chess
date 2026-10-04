## Money for every capture, optionally only with one piece type.
class_name CaptureBonusGambit
extends GambitData

@export var any_capturer := false
@export var capturer_type := UnitStats.Type.PAWN
@export var bonus := 2


func get_capture_bonus(capturer: UnitStats, _captured: UnitStats) -> int:
	if any_capturer or capturer.type == capturer_type:
		return bonus
	return 0
