extends GutTest

const Type := UnitStats.Type
const Team := UnitStats.Team
const CENTER := Vector2i(2, 2)


func _moves(pieces: Dictionary, from: Vector2i) -> Array[Vector2i]:
	var moves := MoveRules.get_legal_moves(PieceFactory.board_with(pieces), from)
	moves.sort()
	return moves


func _sorted(tiles: Array[Vector2i]) -> Array[Vector2i]:
	var copy := tiles.duplicate()
	copy.sort()
	return copy


func test_empty_tile_has_no_moves() -> void:
	assert_eq(_moves({}, CENTER), [] as Array[Vector2i])


func test_forward_direction() -> void:
	assert_eq(MoveRules.get_forward(Team.WHITE), Vector2i.UP)
	assert_eq(MoveRules.get_forward(Team.BLACK), Vector2i.DOWN)


# --- Pawn ---

func test_white_pawn_moves_up_one_tile() -> void:
	var moves := _moves({CENTER: PieceFactory.make(Type.PAWN, Team.WHITE)}, CENTER)
	assert_eq(moves, [Vector2i(2, 1)] as Array[Vector2i])


func test_black_pawn_moves_down_one_tile() -> void:
	var moves := _moves({CENTER: PieceFactory.make(Type.PAWN, Team.BLACK)}, CENTER)
	assert_eq(moves, [Vector2i(2, 3)] as Array[Vector2i])


func test_pawn_is_blocked_by_any_piece_ahead() -> void:
	var pawn := PieceFactory.make(Type.PAWN)

	var blocked_by_ally := _moves({CENTER: pawn, Vector2i(2, 1): PieceFactory.make(Type.ROOK)}, CENTER)
	var blocked_by_enemy := _moves({CENTER: pawn, Vector2i(2, 1): PieceFactory.make(Type.ROOK, Team.BLACK)}, CENTER)

	assert_eq(blocked_by_ally, [] as Array[Vector2i])
	assert_eq(blocked_by_enemy, [] as Array[Vector2i])


func test_pawn_captures_diagonally_only_enemies() -> void:
	var moves := _moves({
		CENTER: PieceFactory.make(Type.PAWN),
		Vector2i(1, 1): PieceFactory.make(Type.PAWN, Team.BLACK),
		Vector2i(3, 1): PieceFactory.make(Type.PAWN, Team.WHITE),
	}, CENTER)

	assert_eq(moves, _sorted([Vector2i(1, 1), Vector2i(2, 1)]))


func test_pawn_on_last_row_has_no_moves() -> void:
	var moves := _moves({Vector2i(2, 0): PieceFactory.make(Type.PAWN)}, Vector2i(2, 0))
	assert_eq(moves, [] as Array[Vector2i])


# --- Knight ---

func test_knight_in_center_has_eight_moves() -> void:
	var moves := _moves({CENTER: PieceFactory.make(Type.KNIGHT)}, CENTER)
	assert_eq(moves.size(), 8)


func test_knight_in_corner_has_two_moves() -> void:
	var moves := _moves({Vector2i(0, 4): PieceFactory.make(Type.KNIGHT)}, Vector2i(0, 4))
	assert_eq(moves, _sorted([Vector2i(1, 2), Vector2i(2, 3)]))


func test_knight_jumps_over_pieces_but_not_onto_allies() -> void:
	var pieces := {CENTER: PieceFactory.make(Type.KNIGHT)}
	for direction in MoveRules.ALL_DIRECTIONS:
		pieces[CENTER + direction] = PieceFactory.make(Type.PAWN)
	pieces[Vector2i(3, 0)] = PieceFactory.make(Type.PAWN, Team.WHITE)
	pieces[Vector2i(1, 0)] = PieceFactory.make(Type.PAWN, Team.BLACK)

	var moves := _moves(pieces, CENTER)

	assert_eq(moves.size(), 7)
	assert_does_not_have(moves, Vector2i(3, 0))
	assert_has(moves, Vector2i(1, 0))


# --- Bishop ---

func test_bishop_in_center_covers_both_diagonals() -> void:
	var moves := _moves({CENTER: PieceFactory.make(Type.BISHOP)}, CENTER)
	assert_eq(moves, _sorted([
		Vector2i(0, 0), Vector2i(1, 1), Vector2i(3, 3), Vector2i(4, 4),
		Vector2i(4, 0), Vector2i(3, 1), Vector2i(1, 3), Vector2i(0, 4),
	]))


func test_bishop_stops_before_ally_and_on_enemy() -> void:
	var moves := _moves({
		CENTER: PieceFactory.make(Type.BISHOP),
		Vector2i(1, 1): PieceFactory.make(Type.PAWN, Team.WHITE),
		Vector2i(3, 3): PieceFactory.make(Type.PAWN, Team.BLACK),
	}, CENTER)

	assert_eq(moves, _sorted([
		Vector2i(3, 3),
		Vector2i(4, 0), Vector2i(3, 1), Vector2i(1, 3), Vector2i(0, 4),
	]))


# --- Rook ---

func test_rook_in_center_has_eight_moves() -> void:
	var moves := _moves({CENTER: PieceFactory.make(Type.ROOK)}, CENTER)
	assert_eq(moves, _sorted([
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 3), Vector2i(2, 4),
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(3, 2), Vector2i(4, 2),
	]))


func test_rook_cannot_pass_through_enemy() -> void:
	var moves := _moves({
		Vector2i(0, 4): PieceFactory.make(Type.ROOK),
		Vector2i(0, 2): PieceFactory.make(Type.PAWN, Team.BLACK),
	}, Vector2i(0, 4))

	assert_has(moves, Vector2i(0, 2))
	assert_does_not_have(moves, Vector2i(0, 1))
	assert_does_not_have(moves, Vector2i(0, 0))


# --- Queen ---

func test_queen_in_center_has_sixteen_moves() -> void:
	var moves := _moves({CENTER: PieceFactory.make(Type.QUEEN)}, CENTER)
	assert_eq(moves.size(), 16)


# --- King ---

func test_king_in_center_has_eight_moves() -> void:
	var moves := _moves({CENTER: PieceFactory.make(Type.KING)}, CENTER)
	assert_eq(moves.size(), 8)


func test_king_in_corner_has_three_moves() -> void:
	var moves := _moves({Vector2i(4, 4): PieceFactory.make(Type.KING)}, Vector2i(4, 4))
	assert_eq(moves, _sorted([Vector2i(3, 3), Vector2i(3, 4), Vector2i(4, 3)]))


func test_king_can_capture_enemy_but_not_ally() -> void:
	var moves := _moves({
		CENTER: PieceFactory.make(Type.KING),
		Vector2i(2, 1): PieceFactory.make(Type.PAWN, Team.BLACK),
		Vector2i(2, 3): PieceFactory.make(Type.PAWN, Team.WHITE),
	}, CENTER)

	assert_has(moves, Vector2i(2, 1))
	assert_does_not_have(moves, Vector2i(2, 3))
