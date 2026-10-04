## Some boss pieces start in STASIS: they can't move or be captured for a few boss turns.
class_name StasisBoss
extends BossData

const STASIS_TINT := Color(0.55, 0.75, 1.0)

@export var count := 2
## Boss turns before the STASIS wears off.
@export var duration := 3


func setup_battle(arena: Arena) -> void:
	var grid := arena.board.unit_grid
	var enemy_tiles: Array[Vector2i] = []
	for tile: Vector2i in grid.units:
		var unit := grid.units[tile] as Unit
		if unit and unit.stats.team != arena.preparation.player_team:
			enemy_tiles.append(tile)
	
	for i in mini(count, enemy_tiles.size()):
		var tile: Vector2i = enemy_tiles.pop_at(RunState.rng.randi_range(0, enemy_tiles.size() - 1))
		grid.frozen_tiles[tile] = true
		(grid.units[tile] as Unit).modulate = STASIS_TINT
	
	# State lives in the closure: this resource is shared by every battle.
	var boss_turns := [0]
	var boss_team := UnitStats.get_opponent(arena.preparation.player_team)
	arena.turn_manager.turn_started.connect(func(team: UnitStats.Team) -> void:
		if team != boss_team or grid.frozen_tiles.is_empty():
			return
		boss_turns[0] += 1
		if boss_turns[0] > duration:
			end_stasis(grid)
	)


static func end_stasis(grid: UnitGrid) -> void:
	for tile in grid.frozen_tiles:
		var unit := grid.units[tile] as Unit
		if unit:
			unit.modulate = Color.WHITE
	grid.frozen_tiles.clear()
