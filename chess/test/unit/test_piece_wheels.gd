extends GutTest

const PIECE_WHEELS = preload("res://scenes/piece_wheels/piece_wheels.tscn")
const WHITE_PAWN = preload("res://data/pieces/white_pawn.tres")
const WHITE_KNIGHT = preload("res://data/pieces/white_knight.tres")

var wheels: PieceWheels


func before_each() -> void:
	RunState.reset()
	wheels = PIECE_WHEELS.instantiate()
	wheels.next_scene = ""
	wheels.stop_delay = 0.0
	add_child_autofree(wheels)


func after_all() -> void:
	RunState.reset()


func _texture_region(rect: TextureRect) -> Rect2:
	return (rect.texture as AtlasTexture).region


func test_default_pool_is_white_pieces_with_weights() -> void:
	assert_eq(wheels.pool.size(), wheels.weights.size())
	assert_has(wheels.pool, WHITE_PAWN)
	assert_has(wheels.pool, WHITE_KNIGHT)
	for piece in wheels.pool:
		assert_eq(piece.team, UnitStats.Team.WHITE)
		assert_ne(piece.type, UnitStats.Type.QUEEN, "no queen from the starting wheels")


func test_rolls_one_piece_per_reel_from_the_pool() -> void:
	assert_eq(wheels.results.size(), PieceWheels.REEL_COUNT)
	for piece in wheels.results:
		assert_has(wheels.pool, piece)


func test_results_are_reproducible_with_the_run_seed() -> void:
	RunState.rng.seed = 99
	var first: PieceWheels = PIECE_WHEELS.instantiate()
	first.next_scene = ""
	add_child_autofree(first)
	RunState.rng.seed = 99
	var second: PieceWheels = PIECE_WHEELS.instantiate()
	second.next_scene = ""
	add_child_autofree(second)
	
	assert_eq(first.results, second.results)


func test_reels_spin_until_stopped() -> void:
	wheels.set_process(false)
	var before := _texture_region(wheels.reels[0])
	
	# Exactly one spin step: with two pieces in the pool the icon must change.
	wheels._process(wheels.spin_interval)
	
	assert_ne(_texture_region(wheels.reels[0]), before, "the reel should change icon while spinning")


func test_stop_shows_results_and_turns_button_into_start() -> void:
	wheels.action_button.pressed.emit()
	await wait_process_frames(2)
	
	assert_true(wheels.is_done())
	assert_eq(wheels.action_button.text, "Start!")
	assert_false(wheels.action_button.disabled)
	for i in PieceWheels.REEL_COUNT:
		assert_eq(_texture_region(wheels.reels[i]), wheels.results[i].create_icon().region)


func test_stopped_reels_keep_their_result() -> void:
	wheels.action_button.pressed.emit()
	for i in 3:
		wheels._process(wheels.spin_interval)
	
	for i in PieceWheels.REEL_COUNT:
		assert_eq(_texture_region(wheels.reels[i]), wheels.results[i].create_icon().region)


func test_reels_stop_one_after_another() -> void:
	wheels.stop_delay = 0.2
	wheels.action_button.pressed.emit()
	
	assert_eq(wheels.stopped_count, 1)
	assert_true(wheels.action_button.disabled)
	await wait_seconds(0.25)
	assert_eq(wheels.stopped_count, 2)


func test_start_gives_the_results_to_the_run() -> void:
	wheels.action_button.pressed.emit()
	await wait_process_frames(2)
	watch_signals(wheels)
	
	wheels.action_button.pressed.emit()
	
	assert_eq(RunState.pieces, wheels.results)
	assert_signal_emitted(wheels, "finished")


func test_icon_uses_the_piece_sprite() -> void:
	var icon := WHITE_KNIGHT.create_icon()
	
	assert_eq(icon.atlas, UnitStats.TEXTURE)
	assert_eq(icon.region, Rect2(Vector2(WHITE_KNIGHT.skin_coordinates) * 8, Vector2(8, 8)))
