## The enemy pieces of one battle.
class_name EncounterData
extends Resource

## Difficulty, matches the run stage (1 to RunState.STAGE_COUNT).
@export_range(1, 5) var stage := 1
@export var is_boss := false
## Board tile -> enemy piece. Enemy tiles are the top rows of the board.
@export var pieces: Dictionary[Vector2i, UnitStats] = {}
