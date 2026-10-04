extends GutTest

const SHOP_SCREEN = preload("res://scenes/shop/shop_screen.tscn")
const WHITE_PAWN = preload("res://data/pieces/white_pawn.tres")
const WHITE_KNIGHT = preload("res://data/pieces/white_knight.tres")
const WHITE_BISHOP = preload("res://data/pieces/white_bishop.tres")
const HUNTER = preload("res://data/tiles/hunter.tres")
const ROYAL_TAX = preload("res://data/gambits/royal_tax.tres")
const PIGGY_BANK = preload("res://data/gambits/piggy_bank.tres")
const CHESS_1 = preload("res://data/tokens/chess_token_1.tres")
const CHESS_2 = preload("res://data/tokens/chess_token_2.tres")
const CHESS_3 = preload("res://data/tokens/chess_token_3.tres")
const TILE_1 = preload("res://data/tokens/tile_token_1.tres")
const TILE_2 = preload("res://data/tokens/tile_token_2.tres")
const GAMBIT_TOKEN = preload("res://data/tokens/gambit_token.tres")


func before_each() -> void:
	RunState.reset()
	Tooltip.hide_tooltip()


func after_all() -> void:
	RunState.reset()


# --- Prices ---

func test_piece_prices() -> void:
	assert_eq(WHITE_PAWN.price, 2)
	assert_eq(WHITE_KNIGHT.price, 5)


func test_sell_price_is_half_rounded_up() -> void:
	assert_eq(WHITE_PAWN.get_sell_price(), 1)
	assert_eq(WHITE_KNIGHT.get_sell_price(), 3, "moodboard shows a knight selling for $3")


func test_display_name() -> void:
	assert_eq(WHITE_KNIGHT.get_display_name(), "Knight")


# --- Tokens data (like the wiki: chess I/II/III cost $5/$7/$12) ---

func test_chess_tokens_offer_one_two_or_three_pieces() -> void:
	assert_eq([CHESS_1.choices, CHESS_2.choices, CHESS_3.choices], [1, 2, 3])
	assert_eq([CHESS_1.price, CHESS_2.price, CHESS_3.price], [5, 7, 12])


func test_every_token_is_complete() -> void:
	assert_eq(RunState.TOKEN_POOL.size(), RunState.TOKEN_WEIGHTS.size())
	var regions := {}
	for token in RunState.TOKEN_POOL:
		assert_ne(token.display_name, "", token.resource_path)
		assert_ne(token.description, "", token.resource_path)
		assert_true(Rect2(Vector2.ZERO, TokenData.TEXTURE.get_size()).encloses(token.icon_region), token.resource_path)
		assert_false(regions.has(token.icon_region), "%s has its own art" % token.resource_path)
		regions[token.icon_region] = true


# --- Restock / reroll ---

func test_new_run_has_an_empty_shop() -> void:
	assert_eq(RunState.item_offers, [null, null, null] as Array[Resource])
	assert_eq(RunState.token_offers, [null, null, null] as Array[TokenData])


func test_restock_fills_items_and_tokens() -> void:
	RunState.restock_shop()
	
	for item in RunState.item_offers:
		assert_true(item is GambitData or item is UnitStats)
	for token in RunState.token_offers:
		assert_has(RunState.TOKEN_POOL, token)


func test_top_row_sells_gambits_and_pieces() -> void:
	var seen_gambit := false
	var seen_piece := false
	for i in 30:
		RunState.restock_shop()
		for item in RunState.item_offers:
			seen_gambit = seen_gambit or item is GambitData
			seen_piece = seen_piece or item is UnitStats
	
	assert_true(seen_gambit)
	assert_true(seen_piece)


func test_reroll_costs_money() -> void:
	RunState.money = 5
	
	assert_true(RunState.reroll_shop())
	assert_eq(RunState.money, 5 - RunState.REROLL_PRICE)


func test_cannot_reroll_without_money() -> void:
	RunState.money = RunState.REROLL_PRICE - 1
	
	assert_false(RunState.reroll_shop())


# --- Locks (on the top row, like the original) ---

func test_toggle_lock() -> void:
	RunState.item_offers = [ROYAL_TAX, null, null]
	
	RunState.toggle_lock(0)
	assert_true(RunState.item_locks[0])
	RunState.toggle_lock(0)
	assert_false(RunState.item_locks[0])


func test_cannot_lock_an_empty_slot() -> void:
	RunState.toggle_lock(0)
	
	assert_false(RunState.item_locks[0])


func test_locked_item_survives_restock() -> void:
	RunState.item_offers = [null, PIGGY_BANK, WHITE_BISHOP]
	RunState.toggle_lock(1)
	RunState.toggle_lock(2)
	
	for i in 20:
		RunState.restock_shop()
		assert_eq(RunState.item_offers[1], PIGGY_BANK)
		assert_eq(RunState.item_offers[2], WHITE_BISHOP)
		assert_eq(RunState.item_offers.count(PIGGY_BANK), 1, "never offered twice")


func test_buying_unlocks_the_slot() -> void:
	RunState.item_offers = [WHITE_BISHOP, null, null]
	RunState.toggle_lock(0)
	RunState.money = 100
	
	RunState.buy_item(0)
	
	assert_false(RunState.item_locks[0])


# --- Items ---

func test_buy_piece_item() -> void:
	RunState.item_offers = [WHITE_BISHOP, null, null]
	RunState.money = 7
	
	assert_true(RunState.buy_item(0))
	assert_eq(RunState.money, 2)
	assert_eq(RunState.pieces.back(), WHITE_BISHOP)
	assert_null(RunState.item_offers[0])


func test_cannot_buy_piece_with_full_stock() -> void:
	RunState.item_offers = [WHITE_PAWN, null, null]
	RunState.money = 100
	while RunState.pieces.size() < RunState.MAX_PIECES:
		RunState.pieces.append(WHITE_PAWN)
	
	assert_false(RunState.buy_item(0))


# --- Tokens ---

func test_buying_a_token_rolls_its_choices() -> void:
	RunState.token_offers = [CHESS_3, null, null]
	RunState.money = 20
	
	var rolled := RunState.buy_token(0)
	
	assert_eq(rolled.size(), 3)
	assert_eq(RunState.money, 8)
	assert_null(RunState.token_offers[0])
	assert_eq(RunState.pending_choices, rolled)
	var distinct := {}
	for piece in rolled:
		assert_has(RunState.SHOP_POOL, piece)
		distinct[piece] = true
	assert_eq(distinct.size(), 3, "different pieces")


func test_claiming_keeps_only_one_reward() -> void:
	RunState.token_offers = [CHESS_2, null, null]
	RunState.money = 20
	var rolled := RunState.buy_token(0)
	var pieces_before := RunState.pieces.size()
	
	assert_true(RunState.claim_choice(1))
	
	assert_eq(RunState.pieces.size(), pieces_before + 1)
	assert_eq(RunState.pieces.back(), rolled[1])
	assert_true(RunState.pending_choices.is_empty())


func test_tile_tokens_roll_distinct_tiles() -> void:
	RunState.token_offers = [TILE_2, TILE_1, null]
	RunState.money = 50
	
	var rolled := RunState.buy_token(0)
	assert_eq(rolled.size(), 3)
	for tile in rolled:
		assert_has(RunState.TILE_POOL, tile)
		assert_eq(rolled.count(tile), 1)
	RunState.claim_choice(0)
	
	assert_eq(RunState.tiles, [rolled[0]] as Array[SpecialTileData])
	assert_eq(RunState.buy_token(1).size(), 1)


func test_gambit_token_rolls_unowned_gambits_of_one_rarity() -> void:
	RunState.token_offers = [GAMBIT_TOKEN, null, null]
	RunState.gambits = [ROYAL_TAX]
	RunState.money = 50
	
	var rolled := RunState.buy_token(0)
	
	assert_gt(rolled.size(), 0)
	for gambit in rolled:
		assert_true(gambit is GambitData)
		assert_ne(gambit, ROYAL_TAX, "already owned")
		assert_eq(rolled.count(gambit), 1)
	RunState.claim_choice(0)
	assert_has(RunState.gambits, rolled[0])


func test_one_token_at_a_time() -> void:
	RunState.token_offers = [CHESS_1, CHESS_1, null]
	RunState.money = 50
	RunState.buy_token(0)
	
	assert_false(RunState.can_buy_token(1), "keep a reward first")
	RunState.claim_choice(0)
	assert_true(RunState.can_buy_token(1))


func test_cannot_buy_tokens_without_room() -> void:
	RunState.token_offers = [CHESS_1, TILE_1, GAMBIT_TOKEN]
	RunState.money = 100
	while RunState.pieces.size() < RunState.MAX_PIECES:
		RunState.pieces.append(WHITE_PAWN)
	for i in RunState.MAX_TILES:
		RunState.tiles.append(HUNTER)
	RunState.gambits = RunState.GAMBIT_POOL.duplicate()
	
	for i in 3:
		assert_false(RunState.can_buy_token(i), str(i))


func test_cannot_buy_a_token_without_money() -> void:
	RunState.token_offers = [CHESS_3, null, null]
	RunState.money = 11
	
	assert_eq(RunState.buy_token(0).size(), 0)
	assert_eq(RunState.money, 11)


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


# --- Selling (in the arena, not in the shop) ---

func test_sell_piece() -> void:
	RunState.pieces = [WHITE_PAWN, WHITE_KNIGHT]
	
	assert_true(RunState.sell_piece(1))
	assert_eq(RunState.money, 3)


func test_cannot_sell_the_last_piece() -> void:
	RunState.pieces = [WHITE_KNIGHT]
	
	assert_false(RunState.sell_piece(0))


# --- Screen ---

func _create_screen(items := [], tokens := []) -> ShopScreen:
	var screen: ShopScreen = SHOP_SCREEN.instantiate()
	screen.next_scene = ""
	add_child_autofree(screen)
	# The restock in _ready replaces the offers, so set them afterwards.
	if not items.is_empty():
		RunState.item_offers.assign(items)
	if not tokens.is_empty():
		RunState.token_offers.assign(tokens)
	screen._refresh()
	return screen


func test_screen_layout_matches_the_original() -> void:
	var screen := _create_screen()
	
	assert_eq(screen.item_buttons.size(), 3)
	assert_eq(screen.lock_buttons.size(), 3)
	assert_eq(screen.token_buttons.size(), 3)
	for i in 3:
		assert_eq(screen.item_buttons[i].position, ShopScreen.ITEM_CARD_POSITIONS[i])
		assert_eq(screen.token_buttons[i].position, ShopScreen.TOKEN_CARD_POSITIONS[i])
		assert_lt(screen.item_tags[i].position.y, screen.item_buttons[i].position.y + ShopScreen.CARD_SIZE.y, "tag overlaps the card")


func test_cards_are_red_for_gambits_and_blue_for_pieces() -> void:
	var screen := _create_screen([ROYAL_TAX, WHITE_BISHOP, null])
	
	var gambit_style := screen.item_buttons[0].get_theme_stylebox("normal") as StyleBoxFlat
	var piece_style := screen.item_buttons[1].get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(gambit_style.bg_color, ShopScreen.GAMBIT_CARD)
	assert_eq(piece_style.bg_color, ShopScreen.PIECE_CARD)
	assert_eq(screen.item_tags[2].text, "Sold")


func test_tokens_show_their_token_art() -> void:
	var screen := _create_screen([], [CHESS_2, TILE_1, GAMBIT_TOKEN])
	
	for i in 3:
		assert_eq((screen.token_buttons[i].icon as AtlasTexture).region, RunState.token_offers[i].icon_region)
	assert_eq(screen.token_tags[0].text, "$7")


func test_clicking_an_item_buys_it() -> void:
	RunState.money = 100
	var screen := _create_screen([WHITE_BISHOP, null, null])
	
	screen.item_buttons[0].pressed.emit()
	
	assert_eq(RunState.pieces.back(), WHITE_BISHOP)
	assert_eq(screen.item_tags[0].text, "Sold")
	assert_eq(screen.stock_icons.get_child_count(), RunState.pieces.size())


func test_clicking_a_token_opens_the_choice_popup() -> void:
	RunState.money = 100
	var screen := _create_screen([], [CHESS_3, null, null])
	
	screen.token_buttons[0].pressed.emit()
	
	assert_true(screen.choice_panel.visible)
	assert_eq(screen.choice_title.text, "Chess Token III")
	assert_eq(screen.choice_buttons.size(), 3)
	assert_true(screen.next_button.disabled, "keep a reward before leaving")


func test_picking_a_choice_closes_the_popup() -> void:
	RunState.money = 100
	var screen := _create_screen([], [CHESS_2, null, null])
	screen.token_buttons[0].pressed.emit()
	var kept := RunState.pending_choices[1]
	
	screen.choice_buttons[1].pressed.emit()
	
	assert_false(screen.choice_panel.visible)
	assert_eq(RunState.pieces.back(), kept)
	assert_false(screen.next_button.disabled)


func test_lock_button_toggles_the_lock() -> void:
	var screen := _create_screen([ROYAL_TAX, ROYAL_TAX, PIGGY_BANK])
	
	screen.lock_buttons[2].pressed.emit()
	
	assert_true(RunState.item_locks[2])
	assert_true(screen.lock_buttons[2].locked)


func test_reroll_button_rerolls() -> void:
	RunState.money = 2
	var screen := _create_screen()
	
	screen.reroll_button.pressed.emit()
	
	assert_eq(RunState.money, 0)
	assert_true(screen.reroll_button.disabled)
	assert_eq(screen.reroll_tag.text, "$2")


func test_upgrade_button_upgrades() -> void:
	RunState.money = 10
	var screen := _create_screen()
	assert_eq(screen.upgrade_tag.text, "$10")
	assert_eq(screen.upgrade_count.text, "3/%d" % RunState.MAX_BOARD_PIECES_LIMIT)
	
	screen.upgrade_button.pressed.emit()
	
	assert_eq(RunState.max_board_pieces, 4)
	assert_eq(screen.upgrade_tag.text, "$15")
	screen.upgrade_button.mouse_entered.emit()
	assert_eq(Tooltip.body.text, "Max pieces on board: 4 -> 5")
	screen.upgrade_button.mouse_exited.emit()


func test_tooltips() -> void:
	var screen := _create_screen([WHITE_BISHOP, null, null], [TILE_2, null, null])
	
	screen.item_buttons[0].mouse_entered.emit()
	assert_eq(Tooltip.title.text, "Bishop")
	screen.token_buttons[0].mouse_entered.emit()
	assert_eq(Tooltip.title.text, "Tile Token II")
	assert_eq(Tooltip.subtitle.text, "Token")


func test_stock_shows_the_run_pieces() -> void:
	RunState.pieces = [WHITE_PAWN, WHITE_KNIGHT, WHITE_PAWN]
	var screen := _create_screen()
	
	assert_eq(screen.stock_icons.get_child_count(), 3)
	assert_eq((screen.stock_icons.get_child(1) as TextureRect).size, Vector2(8, 8))


func test_info_panel_names_the_boss_only_before_the_boss_battle() -> void:
	var screen := _create_screen()
	assert_eq(screen.info_title.text, "Prepare your strategy!")
	assert_false(screen.info_body.visible)
	screen.free()
	
	for i in RunState.GAMES_PER_STAGE - 1:
		RunState.advance()
	var boss_screen := _create_screen()
	
	assert_eq(boss_screen.info_title.text, RunState.boss.display_name)
	assert_eq(boss_screen.info_body.text, RunState.boss.description)


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
