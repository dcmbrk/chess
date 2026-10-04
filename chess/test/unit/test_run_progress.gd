extends GutTest

const HUD = preload("res://scenes/ui/hud/hud.tscn")
const ARENA = preload("res://scenes/arena/arena.tscn")
const WHITE_KNIGHT = preload("res://data/pieces/white_knight.tres")


func before_each() -> void:
	RunState.reset()


func after_all() -> void:
	RunState.reset()


# --- RunState progress ---

func test_run_starts_at_stage_one_game_one() -> void:
	assert_eq([RunState.stage, RunState.game], [1, 1])
	assert_false(RunState.is_boss_game())


func test_last_game_of_a_stage_is_the_boss() -> void:
	for i in RunState.GAMES_PER_STAGE - 1:
		RunState.advance()
	
	assert_eq([RunState.stage, RunState.game], [1, RunState.GAMES_PER_STAGE])
	assert_true(RunState.is_boss_game())


func test_beating_the_boss_starts_the_next_stage() -> void:
	for i in RunState.GAMES_PER_STAGE:
		RunState.advance()
	
	assert_eq([RunState.stage, RunState.game], [2, 1])


func test_run_completes_after_the_last_boss() -> void:
	var total_games := RunState.STAGE_COUNT * RunState.GAMES_PER_STAGE
	for i in total_games - 1:
		assert_false(RunState.advance(), "game %d should not complete the run" % (i + 1))
	
	assert_true(RunState.advance())


func test_reset_restarts_progress() -> void:
	RunState.advance()
	RunState.advance()
	
	RunState.reset()
	
	assert_eq([RunState.stage, RunState.game], [1, 1])


func test_pick_encounter_matches_stage_and_boss() -> void:
	for i in RunState.GAMES_PER_STAGE + RunState.GAMES_PER_STAGE - 1:
		RunState.advance()
	
	var encounter := RunState.pick_encounter()
	
	assert_eq(encounter.stage, 2)
	assert_true(encounter.is_boss)


# --- Encounter library ---

func test_every_stage_has_normal_and_boss_encounters() -> void:
	for stage in range(1, RunState.STAGE_COUNT + 1):
		for is_boss in [false, true]:
			var found := RunState.ENCOUNTERS.encounters.any(func(e: EncounterData) -> bool:
				return e.stage == stage and e.is_boss == is_boss
			)
			assert_true(found, "stage %d boss=%s" % [stage, is_boss])


func test_encounters_only_use_black_pieces_in_the_enemy_zone() -> void:
	for encounter in RunState.ENCOUNTERS.encounters:
		assert_false(encounter.pieces.is_empty(), encounter.resource_path)
		for tile: Vector2i in encounter.pieces:
			var piece: UnitStats = encounter.pieces[tile]
			assert_true(Rect2i(0, 0, 5, 3).has_point(tile), "%s: %s" % [encounter.resource_path, tile])
			assert_eq(piece.team, UnitStats.Team.BLACK, encounter.resource_path)


func test_pick_falls_back_to_an_easier_stage() -> void:
	var library := EncounterLibrary.new()
	var easy := EncounterData.new()
	easy.stage = 1
	library.encounters = [easy]
	
	assert_eq(library.pick(3, false, RandomNumberGenerator.new()), easy)
	assert_null(library.pick(3, true, RandomNumberGenerator.new()), "no boss at all")


func test_pick_is_reproducible_with_the_same_seed() -> void:
	var first := RandomNumberGenerator.new()
	var second := RandomNumberGenerator.new()
	first.seed = 123
	second.seed = 123
	
	for i in 5:
		assert_eq(RunState.ENCOUNTERS.pick(1, false, first), RunState.ENCOUNTERS.pick(1, false, second))


# --- Progress label ---

func test_progress_text() -> void:
	assert_eq(ProgressLabel.get_progress_text(1, 1), "Stage 1/5  Game 1/5")
	assert_eq(ProgressLabel.get_progress_text(3, 5), "Stage 3/5  Game 5/5  BOSS")


func test_hud_shows_current_progress() -> void:
	RunState.advance()
	var hud: CanvasLayer = add_child_autofree(HUD.instantiate())
	
	assert_eq(hud.get_node("ProgressLabel").text, "Stage 1/5  Game 2/5")


# --- Arena ---

func test_arena_spawns_an_encounter_from_run_state() -> void:
	var arena: Arena = ARENA.instantiate()
	add_child_autofree(arena)
	
	assert_not_null(arena.encounter)
	assert_eq(arena.encounter.stage, 1)
	assert_false(arena.encounter.is_boss)
	var black_units := arena.board.unit_grid.get_all_units().filter(func(unit: Unit) -> bool:
		return unit.stats.team == UnitStats.Team.BLACK
	)
	assert_eq(black_units.size(), arena.encounter.pieces.size())


func test_closing_a_won_battle_advances_the_run() -> void:
	var arena := ArenaHelper.create_arena(self)
	# A graveyard entry makes the arena open the graveyard instead of reloading the scene.
	RunState.lose_piece(WHITE_KNIGHT)
	arena.battle_result.show_result(GameRules.Outcome.WIN, BattleRewards.calculate(GameRules.Outcome.WIN, 0, 0), 0)
	
	arena.battle_result.continue_button.pressed.emit()
	
	assert_eq(RunState.game, 2)
	assert_true(arena.graveyard_panel.visible)
