## When the boss captures a piece, a random piece in the player's Stock (bench) is destroyed.
## Destroyed pieces are gone for good, they don't go to the graveyard.
class_name StockDestroyerBoss
extends BossData


func on_unit_captured(arena: Arena, unit: Unit, by: Unit) -> void:
	var player_team := arena.preparation.player_team
	if by == null or by.stats.team == player_team or unit.stats.team != player_team:
		return
	
	var bench_grid: UnitGrid = arena.get_node("Bench").unit_grid
	var stock := bench_grid.get_all_units()
	if stock.is_empty():
		return
	
	var victim: Unit = stock[RunState.rng.randi_range(0, stock.size() - 1)]
	for tile: Vector2i in bench_grid.units:
		if bench_grid.units[tile] == victim:
			bench_grid.remove_unit(tile)
	RunState.pieces.erase(victim.get_run_stats())
	victim.queue_free()
