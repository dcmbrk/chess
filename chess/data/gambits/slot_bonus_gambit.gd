## More pieces allowed on the board.
class_name SlotBonusGambit
extends GambitData

@export var slots := 1


func get_board_slot_bonus() -> int:
	return slots
