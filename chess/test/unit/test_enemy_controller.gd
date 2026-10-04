extends GutTest

var arena: Arena
var grid: UnitGrid
var enemy: EnemyController
var turn_manager: TurnManager


func before_each() -> void:
	arena = ArenaHelper.create_arena(self)
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	grid = arena.get_node("Board").unit_grid
	enemy = arena.get_node("EnemyController")
	enemy.think_delay = 0.0
	turn_manager = arena.turn_manager
	arena.preparation.start_battle()


func _black_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile: Vector2i in grid.units:
		var unit := grid.units[tile] as Unit
		if unit and unit.stats.team == UnitStats.Team.BLACK:
			tiles.append(tile)
	tiles.sort()
	return tiles


func test_enemy_does_not_move_on_player_turn() -> void:
	var before := _black_tiles()

	await wait_process_frames(5)

	assert_eq(_black_tiles(), before)
	assert_eq(turn_manager.current_team, UnitStats.Team.WHITE)


func test_enemy_answers_after_player_move() -> void:
	var before := _black_tiles()
	var pawn: Unit = grid.units[Vector2i(0, 4)]

	arena.unit_mover.perform_board_move(pawn, Vector2i(0, 4), Vector2i(0, 3))
	assert_eq(turn_manager.current_team, UnitStats.Team.BLACK)

	await wait_process_frames(5)

	assert_ne(_black_tiles(), before, "a black piece should have moved")
	assert_eq(turn_manager.current_team, UnitStats.Team.WHITE)


func test_enemy_does_not_move_after_battle_ended() -> void:
	var pawn: Unit = grid.units[Vector2i(0, 4)]
	arena.unit_mover.perform_board_move(pawn, Vector2i(0, 4), Vector2i(0, 3))
	var before := _black_tiles()
	
	# The battle ends while the enemy is still "thinking".
	turn_manager.active = false
	await wait_process_frames(5)
	
	assert_eq(_black_tiles(), before)
