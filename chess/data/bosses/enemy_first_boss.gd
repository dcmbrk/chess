## The boss moves first.
class_name EnemyFirstBoss
extends BossData


func setup_battle(arena: Arena) -> void:
	arena.turn_manager.starting_team = UnitStats.get_opponent(arena.preparation.player_team)
