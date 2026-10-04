## The player can't put Stock (bench) pieces on the board during the battle.
class_name BanStockBoss
extends BossData


func setup_battle(arena: Arena) -> void:
	arena.unit_mover.allow_stock_in_battle = false
