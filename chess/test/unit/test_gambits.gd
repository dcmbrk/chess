extends GutTest

const SHOP_SCREEN = preload("res://scenes/shop/shop_screen.tscn")
const HUD = preload("res://scenes/ui/hud/hud.tscn")
const BUG_CATCHER = preload("res://data/gambits/bug_catchers_gambit.tres")
const CAVALRY = preload("res://data/gambits/cavalry_bounty.tres")
const HEADHUNTER = preload("res://data/gambits/headhunter.tres")
const PIGGY_BANK = preload("res://data/gambits/piggy_bank.tres")
const ROYAL_TAX = preload("res://data/gambits/royal_tax.tres")
const REINFORCEMENTS = preload("res://data/gambits/reinforcements.tres")
const WHITE_PAWN = preload("res://data/pieces/white_pawn.tres")
const WHITE_KNIGHT = preload("res://data/pieces/white_knight.tres")
const BLACK_PAWN = preload("res://data/pieces/black_pawn.tres")
const Outcome := GameRules.Outcome


func before_each() -> void:
	RunState.reset()


func after_all() -> void:
	RunState.reset()


# --- Data ---

func test_every_gambit_is_complete_and_unique() -> void:
	var names := {}
	for gambit in RunState.GAMBIT_POOL:
		assert_ne(gambit.display_name, "", gambit.resource_path)
		assert_ne(gambit.description, "", gambit.resource_path)
		assert_gt(gambit.price, 0, gambit.resource_path)
		assert_false(names.has(gambit.display_name), "duplicate %s" % gambit.display_name)
		names[gambit.display_name] = true
		assert_true(Rect2i(0, 0, 12, 36).has_point(gambit.icon_coordinates), "icon inside SpriteSheet.png")


func test_icon_region() -> void:
	var icon := ROYAL_TAX.create_icon()
	
	assert_eq(icon.atlas, GambitData.ICON_TEXTURE)
	assert_eq(icon.region, Rect2(Vector2(ROYAL_TAX.icon_coordinates) * 8, Vector2(8, 8)))


# --- Effects ---

func test_capture_bonus_for_one_piece_type() -> void:
	assert_eq(BUG_CATCHER.get_capture_bonus(WHITE_PAWN, BLACK_PAWN), 2)
	assert_eq(BUG_CATCHER.get_capture_bonus(WHITE_KNIGHT, BLACK_PAWN), 0)
	assert_eq(CAVALRY.get_capture_bonus(WHITE_KNIGHT, BLACK_PAWN), 2)


func test_capture_bonus_for_any_piece() -> void:
	assert_eq(HEADHUNTER.get_capture_bonus(WHITE_PAWN, BLACK_PAWN), 1)
	assert_eq(HEADHUNTER.get_capture_bonus(WHITE_KNIGHT, BLACK_PAWN), 1)


func test_capture_bonuses_add_up() -> void:
	RunState.gambits = [BUG_CATCHER, HEADHUNTER]
	
	assert_eq(RunState.get_capture_bonus(WHITE_PAWN, BLACK_PAWN), 3)
	assert_eq(RunState.get_capture_bonus(WHITE_KNIGHT, BLACK_PAWN), 1)


func test_royal_tax_only_on_win() -> void:
	var win := BattleRewards.calculate(Outcome.WIN, 0, 0)
	var draw := BattleRewards.calculate(Outcome.DRAW, 0, 0)
	
	ROYAL_TAX.modify_rewards(win, Outcome.WIN, 0)
	ROYAL_TAX.modify_rewards(draw, Outcome.DRAW, 0)
	
	assert_eq(win.win, BattleRewards.WIN_REWARD + 3)
	assert_eq(draw.win, 0)


func test_piggy_bank_raises_interest_limit() -> void:
	var rewards := BattleRewards.calculate(Outcome.WIN, 0, 100)
	assert_eq(rewards.interest, BattleRewards.MAX_INTEREST)
	
	PIGGY_BANK.modify_rewards(rewards, Outcome.WIN, 100)
	
	assert_eq(rewards.interest, BattleRewards.MAX_INTEREST + 3)


func test_piggy_bank_does_nothing_on_loss() -> void:
	var rewards := BattleRewards.calculate(Outcome.LOSS, 0, 100)
	
	PIGGY_BANK.modify_rewards(rewards, Outcome.LOSS, 100)
	
	assert_eq(rewards.total, 0)


func test_reinforcements_add_a_board_slot() -> void:
	assert_eq(RunState.get_board_slots(), RunState.STARTING_MAX_BOARD_PIECES)
	
	RunState.gambits = [REINFORCEMENTS]
	
	assert_eq(RunState.get_board_slots(), RunState.STARTING_MAX_BOARD_PIECES + 1)


# --- Shop offers ---

func test_restock_offers_distinct_gambits() -> void:
	RunState.restock_shop()
	
	var seen := {}
	for offer in RunState.gambit_offers:
		assert_not_null(offer)
		assert_false(seen.has(offer), "no duplicate offers")
		seen[offer] = true


func test_owned_gambits_are_not_offered() -> void:
	RunState.gambits = [BUG_CATCHER, CAVALRY, HEADHUNTER]
	
	for i in 20:
		RunState.restock_shop()
		for offer in RunState.gambit_offers:
			assert_does_not_have(RunState.gambits, offer)


func test_slots_stay_empty_when_pool_is_exhausted() -> void:
	RunState.gambits = RunState.GAMBIT_POOL.duplicate()
	
	RunState.restock_shop()
	
	assert_eq(RunState.gambit_offers, [null, null, null] as Array[GambitData])


func test_buy_gambit() -> void:
	RunState.gambit_offers = [ROYAL_TAX, null, null]
	RunState.money = 10
	watch_signals(RunState)
	
	assert_true(RunState.buy_gambit(0))
	assert_eq(RunState.money, 2)
	assert_eq(RunState.gambits, [ROYAL_TAX] as Array[GambitData])
	assert_null(RunState.gambit_offers[0])
	assert_signal_emitted(RunState, "gambits_changed")


func test_cannot_buy_gambit_without_money() -> void:
	RunState.gambit_offers = [ROYAL_TAX, null, null]
	RunState.money = 7
	
	assert_false(RunState.buy_gambit(0))
	assert_false(RunState.buy_gambit(1), "empty slot")


func test_cannot_own_more_than_max_gambits() -> void:
	RunState.gambit_offers = [ROYAL_TAX, null, null]
	RunState.money = 100
	for i in RunState.MAX_GAMBITS:
		RunState.gambits.append(BUG_CATCHER)
	
	assert_false(RunState.buy_gambit(0))


func test_reset_clears_gambits() -> void:
	RunState.gambits = [ROYAL_TAX]
	
	RunState.reset()
	
	assert_eq(RunState.gambits.size(), 0)


# --- UI ---

func test_shop_shows_gambit_offers() -> void:
	RunState.money = 100
	var screen: ShopScreen = SHOP_SCREEN.instantiate()
	screen.next_scene = ""
	add_child_autofree(screen)
	
	assert_eq(screen.gambit_offers.get_child_count(), RunState.SHOP_SIZE)
	var first: Button = screen.gambit_offers.get_child(0)
	assert_eq(first.text, "$%d" % RunState.gambit_offers[0].price)
	first.mouse_entered.emit()
	assert_true(Tooltip.is_showing())
	assert_eq(Tooltip.title.text, RunState.gambit_offers[0].display_name)
	assert_eq(Tooltip.body.text, RunState.gambit_offers[0].description)
	first.mouse_exited.emit()
	
	var gambit := RunState.gambit_offers[0]
	first.pressed.emit()
	
	assert_has(RunState.gambits, gambit)
	assert_eq((screen.gambit_offers.get_child(0) as Button).text, "Sold")


func test_hud_shows_owned_gambits() -> void:
	var hud: CanvasLayer = add_child_autofree(HUD.instantiate())
	var bar: GambitBar = hud.get_node("GambitBar")
	assert_eq(bar.get_child_count(), 0)
	
	RunState.gambit_offers = [ROYAL_TAX, PIGGY_BANK, null]
	RunState.money = 100
	RunState.buy_gambit(0)
	RunState.buy_gambit(1)
	
	assert_eq(bar.get_child_count(), 2)
	(bar.get_child(0) as TextureRect).mouse_entered.emit()
	assert_eq(Tooltip.title.text, "Royal Tax")
	assert_eq(Tooltip.subtitle.text, "Rare")
	Tooltip.hide_tooltip()


# --- Arena ---

func test_capture_bonus_is_paid_during_battle() -> void:
	var arena := ArenaHelper.create_arena(self)
	RunState.gambits = [BUG_CATCHER]
	var pawn := ArenaHelper.place_unit(arena, Vector2i(2, 2), WHITE_PAWN)
	arena.preparation.start_battle()
	
	arena.unit_mover.perform_board_move(pawn, Vector2i(2, 2), Vector2i(1, 1))
	
	assert_eq(RunState.money, 2)


func test_enemy_captures_pay_nothing() -> void:
	var arena := ArenaHelper.create_arena(self)
	RunState.gambits = [HEADHUNTER]
	ArenaHelper.place_unit(arena, Vector2i(2, 2), WHITE_KNIGHT)
	ArenaHelper.move_to_board(arena, Vector2i(0, 0), Vector2i(0, 4))
	arena.preparation.start_battle()
	arena.turn_manager.end_turn(arena.board.unit_grid.to_board_state())
	var black_pawn: Unit = arena.board.unit_grid.units[Vector2i(1, 1)]
	
	arena.unit_mover.perform_board_move(black_pawn, Vector2i(1, 1), Vector2i(2, 2))
	
	assert_eq(RunState.money, 0)


func test_reward_gambits_change_the_result_screen() -> void:
	var arena := ArenaHelper.create_arena(self)
	RunState.gambits = [ROYAL_TAX]
	
	arena._on_battle_ended(GameRules.Result.WHITE_WINS)
	
	assert_eq(arena.battle_result.win_amount.text, "$%d" % (BattleRewards.WIN_REWARD + 3))


func test_arena_uses_gambit_board_slots() -> void:
	RunState.reset()
	RunState.gambits = [REINFORCEMENTS]
	var arena: Arena = preload("res://scenes/arena/arena.tscn").instantiate()
	arena.encounter = ArenaHelper.three_pawns()
	add_child_autofree(arena)
	
	assert_eq(arena.preparation.max_pieces, RunState.STARTING_MAX_BOARD_PIECES + 1)
