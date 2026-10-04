extends GutTest

const Team := UnitStats.Team

# With RunState.reset() the bench holds a pawn on (0, 0) and a knight on (0, 1).
var arena: Arena
var mover: UnitMover
var grid: UnitGrid
var bench_grid: UnitGrid
var pawn: Unit
var knight: Unit


func before_each() -> void:
	arena = ArenaHelper.create_arena(self)
	mover = arena.unit_mover
	grid = arena.board.unit_grid
	bench_grid = arena.get_node("Bench").unit_grid
	pawn = ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	knight = bench_grid.units[Vector2i(0, 1)]
	arena.preparation.start_battle()


func after_all() -> void:
	RunState.reset()


func test_deploy_puts_the_unit_on_the_board_and_ends_the_turn() -> void:
	assert_true(mover.perform_deploy(knight, Vector2i(2, 3)))
	
	assert_eq(grid.units[Vector2i(2, 3)], knight)
	assert_null(bench_grid.units[Vector2i(0, 1)])
	assert_eq(knight.global_position, arena.board.get_global_from_tile(Vector2i(2, 3)))
	assert_eq(arena.turn_manager.current_team, Team.BLACK)


func test_cannot_deploy_outside_the_player_rows() -> void:
	assert_false(mover.can_deploy(knight, Vector2i(2, 2)))


func test_cannot_deploy_on_an_occupied_tile() -> void:
	assert_false(mover.can_deploy(knight, Vector2i(0, 4)))


func test_cannot_deploy_on_a_cursed_tile() -> void:
	grid.forbidden_tiles[Vector2i(2, 4)] = Team.WHITE
	
	assert_false(mover.can_deploy(knight, Vector2i(2, 4)))


func test_cannot_deploy_on_the_enemy_turn() -> void:
	arena.unit_mover.perform_board_move(pawn, Vector2i(0, 4), Vector2i(0, 3))
	
	assert_false(mover.can_deploy(knight, Vector2i(2, 4)))


func test_cannot_deploy_past_the_max_pieces() -> void:
	arena.preparation.max_pieces = 1
	
	assert_false(mover.can_deploy(knight, Vector2i(2, 4)))


func test_cannot_deploy_a_unit_already_on_the_board() -> void:
	assert_false(mover.can_deploy(pawn, Vector2i(2, 4)))


func test_cannot_deploy_during_preparation() -> void:
	# Two arenas at once would share the "units" group, so drop the battle one first.
	arena.free()
	var fresh := ArenaHelper.create_arena(self)
	var fresh_knight: Unit = fresh.get_node("Bench").unit_grid.units[Vector2i(0, 1)]
	
	assert_false(fresh.unit_mover.can_deploy(fresh_knight, Vector2i(2, 4)))


func test_rules_board_knows_when_the_player_can_deploy() -> void:
	assert_true(mover.get_rules_board().can_deploy.get(Team.WHITE, false))
	
	arena.preparation.max_pieces = 1
	
	assert_false(mover.get_rules_board().can_deploy.get(Team.WHITE, false))


func test_player_with_only_deploys_left_is_not_skipped() -> void:
	# The only white piece on the board is blocked, but the bench can still be used.
	var board := PieceFactory.board_with({
		Vector2i(2, 2): PieceFactory.make(UnitStats.Type.PAWN, Team.WHITE),
		Vector2i(2, 1): PieceFactory.make(UnitStats.Type.ROOK, Team.BLACK),
	})
	board.can_deploy[Team.WHITE] = true
	
	assert_true(GameRules.has_legal_moves(board, Team.WHITE))
	board.can_deploy[Team.WHITE] = false
	assert_false(GameRules.has_legal_moves(board, Team.WHITE))


func test_deploy_tiles_are_highlighted_while_holding_a_stock_unit() -> void:
	var hints: TileMapLayer = arena.board.get_node("MoveHints")
	
	arena.move_highlighter.show_moves(knight)
	
	var cells := hints.get_used_cells()
	assert_eq(cells.size(), 9, "10 player tiles minus the pawn's")
	assert_does_not_have(cells, Vector2i(0, 4))
	for cell in cells:
		assert_gte(cell.y, 3)
