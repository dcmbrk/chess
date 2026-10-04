extends GutTest

const VICTORY_PANEL = preload("res://scenes/ui/victory/victory_panel.tscn")
const SETTINGS_PANEL = preload("res://scenes/ui/settings/settings_panel.tscn")
const WHITE_PAWN = preload("res://data/pieces/white_pawn.tres")
const WHITE_KNIGHT = preload("res://data/pieces/white_knight.tres")


func before_each() -> void:
	Settings.reset_to_defaults()
	Sfx.last_played = ""


func after_all() -> void:
	Settings.reset_to_defaults()
	get_viewport().canvas_transform = Transform2D.IDENTITY
	RunState.reset()


# --- Sounds ---

func test_every_sound_is_synthesized() -> void:
	for sound_name: String in Sfx.SOUNDS:
		var stream: AudioStreamWAV = Sfx.streams[sound_name]
		var seconds := 0.0
		for note: Array in Sfx.SOUNDS[sound_name].notes:
			seconds += note[1]
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, sound_name)
		assert_almost_eq(stream.data.size(), int(seconds * Sfx.MIX_RATE) * 2, 4, sound_name)


func test_synthesized_sound_fades_out() -> void:
	var stream := Sfx.synthesize([[440.0, 0.1]], Sfx.Wave.SQUARE, 1.0)
	var data := stream.data
	var last_sample := data.decode_s16(data.size() - 2)
	
	assert_lt(absi(last_sample), 1000, "no click at the end")


func test_play_remembers_the_sound() -> void:
	Sfx.play("buy")
	
	assert_eq(Sfx.last_played, "buy")


func test_moving_plays_move_and_capturing_plays_capture() -> void:
	var arena := ArenaHelper.create_arena(self)
	var pawn := ArenaHelper.place_unit(arena, Vector2i(2, 3), WHITE_PAWN)
	arena.preparation.start_battle()
	
	arena.unit_mover.perform_board_move(pawn, Vector2i(2, 3), Vector2i(2, 2))
	assert_eq(Sfx.last_played, "move")
	
	arena.turn_manager.end_turn(arena.board.unit_grid.to_board_state())
	arena.unit_mover.perform_board_move(pawn, Vector2i(2, 2), Vector2i(1, 1))
	assert_eq(Sfx.last_played, "capture")


func test_battle_end_plays_win_or_lose() -> void:
	var arena := ArenaHelper.create_arena(self)
	
	arena._on_battle_ended(GameRules.Result.WHITE_WINS)
	assert_eq(Sfx.last_played, "win")
	
	arena._on_battle_ended(GameRules.Result.BLACK_WINS)
	assert_eq(Sfx.last_played, "lose")


func test_selling_plays_sell() -> void:
	var arena := ArenaHelper.create_arena(self)
	var knight: Unit = arena.get_node("Bench").unit_grid.units[Vector2i(0, 1)]
	
	arena.unit_seller.sell(knight)
	
	assert_eq(Sfx.last_played, "sell")


# --- Sliding pieces ---

func test_moved_unit_slides_to_its_tile() -> void:
	var arena := ArenaHelper.create_arena(self)
	var pawn := ArenaHelper.place_unit(arena, Vector2i(2, 3), WHITE_PAWN)
	arena.preparation.start_battle()
	
	arena.unit_mover.perform_board_move(pawn, Vector2i(2, 3), Vector2i(2, 2))
	
	assert_eq(pawn.global_position, arena.board.get_global_from_tile(Vector2i(2, 2)), "the unit itself is already there")
	assert_eq(pawn.visuals.position, Vector2(0, 8), "the sprite starts from the old tile")
	
	await wait_seconds(Unit.SLIDE_TIME + 0.05)
	
	assert_eq(pawn.visuals.position, Vector2.ZERO)


func test_no_slide_without_animations() -> void:
	Settings.set_animations(false)
	var arena := ArenaHelper.create_arena(self)
	var pawn := ArenaHelper.place_unit(arena, Vector2i(2, 3), WHITE_PAWN)
	arena.preparation.start_battle()
	
	arena.unit_mover.perform_board_move(pawn, Vector2i(2, 3), Vector2i(2, 2))
	
	assert_eq(pawn.visuals.position, Vector2.ZERO)


# --- Screen ---

func test_shake_moves_the_world_then_restores_it() -> void:
	ScreenEffects.shake()
	await wait_process_frames(1)
	assert_ne(get_viewport().canvas_transform, Transform2D.IDENTITY)
	
	await wait_seconds(ScreenEffects.SHAKE_STEP_TIME * (ScreenEffects.SHAKE_STEPS.size() + 2))
	
	assert_eq(get_viewport().canvas_transform, Transform2D.IDENTITY)


func test_no_shake_without_animations() -> void:
	Settings.set_animations(false)
	
	ScreenEffects.shake()
	await wait_process_frames(2)
	
	assert_eq(get_viewport().canvas_transform, Transform2D.IDENTITY)


func test_crt_overlay_follows_the_setting() -> void:
	assert_true(ScreenEffects.crt.visible)
	assert_eq(ScreenEffects.crt.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never blocks clicks")
	assert_not_null((ScreenEffects.crt.material as ShaderMaterial).shader)
	
	Settings.set_crt(false)
	
	assert_false(ScreenEffects.crt.visible)


# --- Settings ---

func test_new_settings_are_saved() -> void:
	Settings.set_animations(false)
	Settings.set_crt(false)
	Settings.animations = true
	Settings.crt = true
	
	Settings.load_settings()
	
	assert_false(Settings.animations)
	assert_false(Settings.crt)


func test_settings_panel_toggles_effects() -> void:
	var panel: SettingsPanel = add_child_autofree(SETTINGS_PANEL.instantiate())
	panel.open()
	assert_eq(panel.animations_button.text, "On")
	
	panel.animations_button.pressed.emit()
	panel.crt_button.pressed.emit()
	
	assert_false(Settings.animations)
	assert_false(Settings.crt)
	assert_eq(panel.crt_button.text, "Off")


# --- Victory ---

func test_victory_panel_shows_run_stats() -> void:
	RunState.reset()
	RunState.money = 42
	var panel: VictoryPanel = add_child_autofree(VICTORY_PANEL.instantiate())
	watch_signals(panel)
	
	panel.open()
	assert_true(panel.visible)
	assert_eq(panel.stats_label.text, "$42 · 2 pieces · 0 gambits")
	
	panel.main_menu_button.pressed.emit()
	assert_signal_emitted(panel, "closed")


func test_beating_the_last_boss_shows_the_victory() -> void:
	var arena := ArenaHelper.create_arena(self)
	RunState.stage = RunState.STAGE_COUNT
	RunState.game = RunState.GAMES_PER_STAGE
	arena.outcome = GameRules.Outcome.WIN
	var wins := Progress.runs_won
	
	arena._on_battle_result_closed()
	
	assert_true(arena.victory_panel.visible)
	assert_eq(Progress.runs_won, wins + 1)
