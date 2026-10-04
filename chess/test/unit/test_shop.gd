extends GutTest

const SHOP_SCREEN = preload("res://scenes/shop/shop_screen.tscn")
const WHITE_PAWN = preload("res://data/pieces/white_pawn.tres")
const WHITE_KNIGHT = preload("res://data/pieces/white_knight.tres")


func before_each() -> void:
	RunState.reset()


func after_all() -> void:
	RunState.reset()


func _offer_everything(piece: UnitStats) -> void:
	for i in RunState.SHOP_SIZE:
		RunState.shop_offers[i] = piece


# --- Prices ---

func test_piece_prices() -> void:
	assert_eq(WHITE_PAWN.price, 2)
	assert_eq(WHITE_KNIGHT.price, 5)


func test_sell_price_is_half_rounded_up() -> void:
	assert_eq(WHITE_PAWN.get_sell_price(), 1)
	assert_eq(WHITE_KNIGHT.get_sell_price(), 3, "moodboard shows a knight selling for $3")


func test_display_name() -> void:
	assert_eq(WHITE_KNIGHT.get_display_name(), "Knight")


# --- Restock / reroll / lock ---

func test_new_run_has_an_empty_shop() -> void:
	assert_eq(RunState.shop_offers.size(), RunState.SHOP_SIZE)
	assert_false(RunState.shop_offers.any(func(offer: UnitStats) -> bool: return offer != null))


func test_restock_fills_every_slot_from_the_pool() -> void:
	RunState.restock_shop()
	
	for offer in RunState.shop_offers:
		assert_has(RunState.SHOP_POOL, offer)


func test_reroll_costs_money() -> void:
	RunState.money = 5
	
	assert_true(RunState.reroll_shop())
	assert_eq(RunState.money, 5 - RunState.REROLL_PRICE)


func test_cannot_reroll_without_money() -> void:
	RunState.money = RunState.REROLL_PRICE - 1
	
	assert_false(RunState.reroll_shop())
	assert_eq(RunState.money, RunState.REROLL_PRICE - 1)


func test_locked_offer_survives_restock() -> void:
	_offer_everything(WHITE_KNIGHT)
	RunState.toggle_lock(1)
	RunState.rng.seed = 1
	
	for i in 20:
		RunState.restock_shop()
		assert_eq(RunState.shop_offers[1], WHITE_KNIGHT)


func test_toggle_lock() -> void:
	_offer_everything(WHITE_PAWN)
	
	RunState.toggle_lock(0)
	assert_true(RunState.shop_locks[0])
	RunState.toggle_lock(0)
	assert_false(RunState.shop_locks[0])


func test_cannot_lock_a_sold_slot() -> void:
	RunState.toggle_lock(0)
	
	assert_false(RunState.shop_locks[0])


# --- Buying ---

func test_buy_offer() -> void:
	_offer_everything(WHITE_KNIGHT)
	RunState.money = 7
	var pieces_before := RunState.pieces.size()
	
	assert_true(RunState.buy_offer(0))
	assert_eq(RunState.money, 2)
	assert_eq(RunState.pieces.size(), pieces_before + 1)
	assert_eq(RunState.pieces.back(), WHITE_KNIGHT)
	assert_null(RunState.shop_offers[0], "the slot is sold")


func test_buying_unlocks_the_slot() -> void:
	_offer_everything(WHITE_PAWN)
	RunState.toggle_lock(0)
	RunState.money = 10
	
	RunState.buy_offer(0)
	
	assert_false(RunState.shop_locks[0])


func test_cannot_buy_without_money() -> void:
	_offer_everything(WHITE_KNIGHT)
	RunState.money = 4
	
	assert_false(RunState.buy_offer(0))
	assert_eq(RunState.shop_offers[0], WHITE_KNIGHT)


func test_cannot_buy_with_full_stock() -> void:
	_offer_everything(WHITE_PAWN)
	RunState.money = 100
	while RunState.pieces.size() < RunState.MAX_PIECES:
		RunState.pieces.append(WHITE_PAWN)
	
	assert_false(RunState.buy_offer(0))


func test_cannot_buy_a_sold_slot() -> void:
	RunState.money = 100
	
	assert_false(RunState.buy_offer(0))


# --- Upgrade ---

func test_upgrade_max_board_pieces() -> void:
	RunState.money = 30
	
	assert_true(RunState.upgrade_max_board_pieces())
	assert_eq(RunState.max_board_pieces, RunState.STARTING_MAX_BOARD_PIECES + 1)
	assert_eq(RunState.money, 20)


func test_upgrade_price_grows() -> void:
	RunState.money = 100
	assert_eq(RunState.get_upgrade_price(), 10)
	
	RunState.upgrade_max_board_pieces()
	
	assert_eq(RunState.get_upgrade_price(), 15)


func test_cannot_upgrade_past_the_limit() -> void:
	RunState.money = 1000
	RunState.max_board_pieces = RunState.MAX_BOARD_PIECES_LIMIT
	
	assert_false(RunState.upgrade_max_board_pieces())


# --- Selling ---

func test_sell_piece() -> void:
	RunState.pieces = [WHITE_PAWN, WHITE_KNIGHT]
	
	assert_true(RunState.sell_piece(1))
	assert_eq(RunState.money, 3)
	assert_eq(RunState.pieces, [WHITE_PAWN] as Array[UnitStats])


func test_cannot_sell_the_last_piece() -> void:
	RunState.pieces = [WHITE_KNIGHT]
	
	assert_false(RunState.sell_piece(0))
	assert_eq(RunState.pieces.size(), 1)


# --- Screen ---

func _create_screen() -> ShopScreen:
	var screen: ShopScreen = SHOP_SCREEN.instantiate()
	screen.next_scene = ""
	add_child_autofree(screen)
	return screen


func _offer_button(screen: ShopScreen, index: int) -> Button:
	return screen.offers.get_child(index).get_child(0)


func _lock_button(screen: ShopScreen, index: int) -> Button:
	return screen.offers.get_child(index).get_child(1)


func test_screen_restocks_and_shows_offers_and_stock() -> void:
	var screen := _create_screen()
	
	assert_eq(screen.offers.get_child_count(), RunState.SHOP_SIZE)
	assert_eq(screen.stock.get_child_count(), RunState.pieces.size())
	for i in RunState.SHOP_SIZE:
		assert_eq(_offer_button(screen, i).text, "$%d" % RunState.shop_offers[i].price)


func test_screen_disables_what_the_player_cannot_afford() -> void:
	var screen := _create_screen()
	
	assert_true(screen.reroll_button.disabled)
	assert_true(screen.upgrade_button.disabled)
	assert_true(_offer_button(screen, 0).disabled)


func test_clicking_an_offer_buys_it() -> void:
	RunState.money = 10
	var screen := _create_screen()
	var piece := RunState.shop_offers[0]
	
	_offer_button(screen, 0).pressed.emit()
	
	assert_eq(RunState.pieces.back(), piece)
	assert_eq(_offer_button(screen, 0).text, "Sold")
	assert_eq(screen.stock.get_child_count(), RunState.pieces.size())


func test_lock_button_toggles_lock() -> void:
	var screen := _create_screen()
	
	_lock_button(screen, 2).pressed.emit()
	
	assert_true(RunState.shop_locks[2])
	assert_eq(_lock_button(screen, 2).text, "Locked")


func test_reroll_button_rerolls() -> void:
	RunState.money = 2
	var screen := _create_screen()
	
	screen.reroll_button.pressed.emit()
	
	assert_eq(RunState.money, 0)
	assert_true(screen.reroll_button.disabled)


func test_upgrade_button_upgrades() -> void:
	RunState.money = 10
	var screen := _create_screen()
	assert_eq(screen.upgrade_button.text, "+1 Slot $10")
	
	screen.upgrade_button.pressed.emit()
	
	assert_eq(RunState.max_board_pieces, 4)
	assert_eq(screen.upgrade_button.text, "+1 Slot $15")
	assert_eq(screen.upgrade_button.tooltip_text, "Max pieces on board: 4")


func test_holding_a_stock_piece_sells_it() -> void:
	RunState.pieces = [WHITE_PAWN, WHITE_KNIGHT]
	var screen := _create_screen()
	var knight_slot: Button = screen.stock.get_child(1)
	assert_eq(knight_slot.text, "+$3")
	
	knight_slot.button_down.emit()
	screen.hold_timer.timeout.emit()
	
	assert_eq(RunState.pieces, [WHITE_PAWN] as Array[UnitStats])
	assert_eq(RunState.money, 3)


func test_releasing_early_does_not_sell() -> void:
	RunState.pieces = [WHITE_PAWN, WHITE_KNIGHT]
	var screen := _create_screen()
	var knight_slot: Button = screen.stock.get_child(1)
	
	knight_slot.button_down.emit()
	knight_slot.button_up.emit()
	screen.hold_timer.timeout.emit()
	
	assert_eq(RunState.pieces.size(), 2)
	assert_true(screen.hold_timer.is_stopped())


func test_next_button_finishes() -> void:
	var screen := _create_screen()
	watch_signals(screen)
	
	screen.next_button.pressed.emit()
	
	assert_signal_emitted(screen, "finished")


# --- Arena ---

func test_arena_uses_the_upgraded_max_pieces() -> void:
	RunState.max_board_pieces = 5
	var arena: Arena = preload("res://scenes/arena/arena.tscn").instantiate()
	arena.encounter = ArenaHelper.three_pawns()
	add_child_autofree(arena)
	
	assert_eq(arena.preparation.max_pieces, 5)
	assert_eq(arena.prep_panel.pieces_label.text, "Pieces 0/5")
