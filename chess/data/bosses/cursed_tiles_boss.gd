## Random empty tiles become CURSED: the player's pieces can't enter them.
class_name CursedTilesBoss
extends BossData

@export var count := 5


func setup_battle(arena: Arena) -> void:
	var grid := arena.board.unit_grid
	var empty_tiles: Array[Vector2i] = []
	for tile: Vector2i in grid.units:
		if not grid.is_tile_occupied(tile):
			empty_tiles.append(tile)
	
	for i in mini(count, empty_tiles.size()):
		var tile: Vector2i = empty_tiles.pop_at(RunState.rng.randi_range(0, empty_tiles.size() - 1))
		grid.forbidden_tiles[tile] = arena.preparation.player_team
	arena.cursed_tiles_overlay.queue_redraw()
