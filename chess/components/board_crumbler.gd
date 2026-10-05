## Crumble Mode: when a battle lasts too long, a tile of the outermost ring
## falls at the end of every turn. A piece standing there falls with it.
class_name BoardCrumbler
extends Node

signal countdown_changed(turns_left: int)
signal tile_crumbled(tile: Vector2i)

@export var board: PlayArea
@export var unit_mover: UnitMover
## Turns (both teams) before the tiles start falling.
@export var turns_before_crumbling := 16

var turns_played := 0


func _ready() -> void:
	unit_mover.turn_ending.connect(_on_turn_ending)


func get_turns_left() -> int:
	return maxi(0, turns_before_crumbling - turns_played)


func is_crumbling() -> bool:
	return get_turns_left() == 0


## Makes one tile of the outermost remaining ring fall. Returns it, or (-1, -1).
func crumble_next_tile() -> Vector2i:
	var grid := board.unit_grid
	var center := Vector2(grid.size - Vector2i.ONE) / 2
	var candidates: Array[Vector2i] = []
	var farthest := -1.0
	for tile: Vector2i in grid.units:
		if grid.holes.has(tile):
			continue
		var distance := maxf(absf(tile.x - center.x), absf(tile.y - center.y))
		if distance > farthest:
			farthest = distance
			candidates.clear()
		if distance == farthest:
			candidates.append(tile)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	
	var tile := candidates[RunState.rng.randi_range(0, candidates.size() - 1)]
	grid.holes[tile] = true
	var unit := grid.units[tile] as Unit
	if unit:
		unit_mover.destroy_unit(unit, tile)
	tile_crumbled.emit(tile)
	return tile


func _on_turn_ending() -> void:
	turns_played += 1
	if turns_played > turns_before_crumbling:
		crumble_next_tile()
	countdown_changed.emit(get_turns_left())
