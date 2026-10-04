## Data that lives for a whole run (survives scene reloads between battles).
extends Node

signal money_changed(money: int)
signal gambits_changed

const STAGE_COUNT := 5
const GAMES_PER_STAGE := 5
const ENCOUNTERS: EncounterLibrary = preload("res://data/encounters/encounter_library.tres")

const STARTING_MONEY := 0
const STARTING_PIECES: Array[UnitStats] = [
	preload("res://data/pieces/white_pawn.tres"),
	preload("res://data/pieces/white_knight.tres"),
]
## Same as the number of bench slots.
const MAX_PIECES := 6
const GRAVEYARD_SIZE := 5
## The moodboard shows captured pieces coming back for $0.
const REVIVE_PRICE := 0

const SHOP_SIZE := 3
const SHOP_POOL: Array[UnitStats] = [
	preload("res://data/pieces/white_pawn.tres"),
	preload("res://data/pieces/white_knight.tres"),
	preload("res://data/pieces/white_bishop.tres"),
	preload("res://data/pieces/white_rook.tres"),
	preload("res://data/pieces/white_queen.tres"),
	preload("res://data/pieces/white_king.tres"),
]
## Same order as SHOP_POOL.
const SHOP_WEIGHTS: Array[int] = [6, 4, 4, 3, 1, 2]
const REROLL_PRICE := 2
const STARTING_MAX_BOARD_PIECES := 3
## Two full rows of the board.
const MAX_BOARD_PIECES_LIMIT := 10
const UPGRADE_BASE_PRICE := 10
const UPGRADE_PRICE_STEP := 5
const BOSS_POOL: Array[BossData] = [
	preload("res://data/bosses/magnus_the_swift.tres"),
	preload("res://data/bosses/hikaru_the_banished.tres"),
	preload("res://data/bosses/tal_the_cursed.tres"),
	preload("res://data/bosses/kev_borclick.tres"),
	preload("res://data/bosses/jawby_fisher.tres"),
]
const TILE_POOL: Array[SpecialTileData] = [
	preload("res://data/tiles/protection.tres"),
	preload("res://data/tiles/benediction.tres"),
	preload("res://data/tiles/hunter.tres"),
	preload("res://data/tiles/phantom.tres"),
]
## Chance for each item of the shop's top row to be a piece instead of a gambit.
const ITEM_PIECE_CHANCE := 0.3
const TOKEN_POOL: Array[TokenData] = [
	preload("res://data/tokens/chess_token_1.tres"),
	preload("res://data/tokens/chess_token_2.tres"),
	preload("res://data/tokens/chess_token_3.tres"),
	preload("res://data/tokens/tile_token_1.tres"),
	preload("res://data/tokens/tile_token_2.tres"),
	preload("res://data/tokens/gambit_token.tres"),
]
## Same order as TOKEN_POOL.
const TOKEN_WEIGHTS: Array[int] = [5, 4, 2, 4, 2, 3]
## Tiles the player may own, placed or not.
const MAX_TILES := 6
const MAX_GAMBITS := 6
const GAMBIT_POOL: Array[GambitData] = [
	preload("res://data/gambits/bug_catchers_gambit.tres"),
	preload("res://data/gambits/cavalry_bounty.tres"),
	preload("res://data/gambits/headhunter.tres"),
	preload("res://data/gambits/piggy_bank.tres"),
	preload("res://data/gambits/royal_tax.tres"),
	preload("res://data/gambits/reinforcements.tres"),
]

var money := STARTING_MONEY:
	set(value):
		money = value
		money_changed.emit(money)
## The player's pieces (the Stock), spawned on the bench before every battle.
var pieces: Array[UnitStats] = []
## The player's last captured pieces, oldest first.
var graveyard: Array[UnitStats] = []
var stage := 1
## The game inside the current stage; the last one is the boss.
var game := 1
## Every random choice of the run comes from this generator, seeded with [member run_seed].
var rng := RandomNumberGenerator.new()
var run_seed := 0
## How many pieces the player may place on the board.
var max_board_pieces := STARTING_MAX_BOARD_PIECES
## Pieces for sale; null means the slot was bought.
## Top row of the shop: GambitData or UnitStats bought directly; null when bought.
var item_offers: Array[Resource] = []
## Locked items are kept when the shop is rerolled or restocked.
var item_locks: Array[bool] = []
## Bottom row of the shop: tokens rolling random rewards; null when bought.
var token_offers: Array[TokenData] = []
## Rewards rolled by the last bought token, waiting for the player to keep one.
var pending_choices: Array[Resource] = []
var gambits: Array[GambitData] = []
## Bought special tiles that are not on the board yet.
var tiles: Array[SpecialTileData] = []
## Special tiles on the board: tile -> data. They stay there between battles.
var placed_tiles: Dictionary[Vector2i, SpecialTileData] = {}
## The boss waiting at the end of the current stage.
var boss: BossData
var _met_bosses: Array[BossData] = []


func _ready() -> void:
	reset()


func add_money(amount: int) -> void:
	money += amount


## Starts a new run. A negative [param new_seed] picks a random one.
func reset(new_seed := -1) -> void:
	run_seed = new_seed if new_seed >= 0 else randi()
	rng.seed = run_seed
	money = STARTING_MONEY
	pieces = STARTING_PIECES.duplicate()
	graveyard.clear()
	stage = 1
	game = 1
	max_board_pieces = STARTING_MAX_BOARD_PIECES
	item_offers.clear()
	item_offers.resize(SHOP_SIZE)
	item_locks.clear()
	item_locks.resize(SHOP_SIZE)
	token_offers.clear()
	token_offers.resize(SHOP_SIZE)
	pending_choices.clear()
	tiles.clear()
	placed_tiles.clear()
	gambits.clear()
	gambits_changed.emit()
	_met_bosses.clear()
	boss = _pick_boss()


func is_boss_game() -> bool:
	return game == GAMES_PER_STAGE


## Moves to the next game. Returns true when the whole run is completed.
func advance() -> bool:
	game += 1
	if game > GAMES_PER_STAGE:
		game = 1
		stage += 1
		boss = _pick_boss()
	return stage > STAGE_COUNT


## A boss not met yet in this run (any boss once all were met).
func _pick_boss() -> BossData:
	var candidates := BOSS_POOL.filter(func(candidate: BossData) -> bool:
		return candidate not in _met_bosses
	)
	if candidates.is_empty():
		candidates = BOSS_POOL.duplicate()
	
	var picked: BossData = candidates[rng.randi_range(0, candidates.size() - 1)]
	_met_bosses.append(picked)
	return picked


func pick_encounter() -> EncounterData:
	return ENCOUNTERS.pick(stage, is_boss_game(), rng)


## Moves a captured piece from the Stock to the graveyard.
func lose_piece(piece: UnitStats) -> void:
	pieces.erase(piece)
	graveyard.append(piece)
	if graveyard.size() > GRAVEYARD_SIZE:
		graveyard.pop_front()


func can_revive(index: int) -> bool:
	return index >= 0 and index < graveyard.size() \
			and money >= REVIVE_PRICE and pieces.size() < MAX_PIECES


## Buys a piece back from the graveyard. Returns false if it isn't possible.
func revive_piece(index: int) -> bool:
	if not can_revive(index):
		return false

	money -= REVIVE_PRICE
	pieces.append(graveyard[index])
	graveyard.remove_at(index)
	return true


# --- Shop ---

## Rerolls every unlocked item and every token.
func restock_shop() -> void:
	for i in SHOP_SIZE:
		if not item_locks[i]:
			item_offers[i] = null
	for i in SHOP_SIZE:
		if not item_locks[i]:
			item_offers[i] = _pick_item_offer()
	
	for i in SHOP_SIZE:
		token_offers[i] = WeightedRandom.pick(TOKEN_POOL, TOKEN_WEIGHTS, rng)


## A piece, or a gambit the player doesn't own and that isn't offered yet.
func _pick_item_offer() -> Resource:
	if rng.randf() >= ITEM_PIECE_CHANCE:
		var gambit := _pick_gambit(GambitData.RARITY_WEIGHTS.keys(), item_offers)
		if gambit:
			return gambit
	return WeightedRandom.pick(SHOP_POOL, SHOP_WEIGHTS, rng)


## A random gambit of one of [param rarities], not owned and not in [param excluded], or null.
func _pick_gambit(rarities: Array, excluded: Array) -> GambitData:
	var candidates := GAMBIT_POOL.filter(func(gambit: GambitData) -> bool:
		return gambit.rarity in rarities and gambit not in gambits and gambit not in excluded
	)
	if candidates.is_empty():
		return null
	
	var weights: Array[int] = []
	for gambit: GambitData in candidates:
		weights.append(GambitData.RARITY_WEIGHTS[gambit.rarity])
	return WeightedRandom.pick(candidates, weights, rng)


func reroll_shop() -> bool:
	if money < REROLL_PRICE:
		return false
	
	money -= REROLL_PRICE
	restock_shop()
	return true


func can_buy_item(index: int) -> bool:
	var item := item_offers[index]
	if item == null or money < item.price:
		return false
	if item is GambitData:
		return gambits.size() < MAX_GAMBITS
	return pieces.size() < MAX_PIECES


func buy_item(index: int) -> bool:
	if not can_buy_item(index):
		return false
	
	var item := item_offers[index]
	money -= item.price
	if item is GambitData:
		gambits.append(item)
		gambits_changed.emit()
	else:
		pieces.append(item)
	Progress.discover(item)
	item_offers[index] = null
	item_locks[index] = false
	return true


func toggle_lock(index: int) -> void:
	if item_offers[index]:
		item_locks[index] = not item_locks[index]


func can_buy_token(index: int) -> bool:
	var token := token_offers[index]
	if token == null or money < token.price or not pending_choices.is_empty():
		return false
	match token.kind:
		TokenData.Kind.CHESS:
			return pieces.size() < MAX_PIECES
		TokenData.Kind.TILE:
			return get_tile_count() < MAX_TILES
	return gambits.size() < MAX_GAMBITS and _pick_gambit(GambitData.RARITY_WEIGHTS.keys(), []) != null


## Pays for the token and rolls its rewards into [member pending_choices].
## The player then keeps one with [method claim_choice].
func buy_token(index: int) -> Array[Resource]:
	if not can_buy_token(index):
		return []
	
	var token := token_offers[index]
	money -= token.price
	token_offers[index] = null
	pending_choices = roll_token(token)
	# A copy: claim_choice clears pending_choices.
	return pending_choices.duplicate()


func roll_token(token: TokenData) -> Array[Resource]:
	var rolled: Array[Resource] = []
	match token.kind:
		TokenData.Kind.CHESS:
			# Different piece types, so every choice means something.
			for i in token.choices:
				var left := SHOP_POOL.filter(func(piece: UnitStats) -> bool: return piece not in rolled)
				var weights: Array[int] = []
				for piece: UnitStats in left:
					weights.append(SHOP_WEIGHTS[SHOP_POOL.find(piece)])
				rolled.append(WeightedRandom.pick(left, weights, rng))
		TokenData.Kind.TILE:
			var left := TILE_POOL.duplicate()
			for i in mini(token.choices, left.size()):
				rolled.append(left.pop_at(rng.randi_range(0, left.size() - 1)))
		TokenData.Kind.GAMBIT:
			# Gachapon: a random rarity first, then gambits of that rarity.
			var rarity_weights: Array[int] = []
			rarity_weights.assign(GambitData.RARITY_WEIGHTS.values())
			var rarity: int = WeightedRandom.pick(GambitData.RARITY_WEIGHTS.keys(), rarity_weights, rng)
			for i in token.choices:
				var gambit := _pick_gambit([rarity], rolled)
				if not gambit:
					gambit = _pick_gambit(GambitData.RARITY_WEIGHTS.keys(), rolled)
				if gambit:
					rolled.append(gambit)
	return rolled


## Keeps one of the rolled rewards; the others are lost.
func claim_choice(index: int) -> bool:
	if index < 0 or index >= pending_choices.size():
		return false
	
	var reward := pending_choices[index]
	if reward is UnitStats:
		pieces.append(reward)
	elif reward is SpecialTileData:
		tiles.append(reward)
	elif reward is GambitData:
		gambits.append(reward)
		gambits_changed.emit()
	Progress.discover(reward)
	pending_choices.clear()
	return true


func get_upgrade_price() -> int:
	return UPGRADE_BASE_PRICE + UPGRADE_PRICE_STEP * (max_board_pieces - STARTING_MAX_BOARD_PIECES)


func can_upgrade() -> bool:
	return max_board_pieces < MAX_BOARD_PIECES_LIMIT and money >= get_upgrade_price()


func upgrade_max_board_pieces() -> bool:
	if not can_upgrade():
		return false
	
	money -= get_upgrade_price()
	max_board_pieces += 1
	return true


## The last piece can't be sold, the player needs something to fight with.
func can_sell(index: int) -> bool:
	return index >= 0 and index < pieces.size() and pieces.size() > 1


func sell_piece(index: int) -> bool:
	if not can_sell(index):
		return false
	
	money += pieces[index].get_sell_price()
	pieces.remove_at(index)
	return true


# --- Gambits ---

func get_capture_bonus(capturer: UnitStats, captured: UnitStats) -> int:
	var bonus := 0
	for gambit in gambits:
		bonus += gambit.get_capture_bonus(capturer, captured)
	return bonus


func apply_gambits_to_rewards(rewards: BattleRewards, outcome: GameRules.Outcome) -> void:
	for gambit in gambits:
		gambit.modify_rewards(rewards, outcome, money)


## Pieces the player may place on the board, including gambit bonuses.
func get_board_slots() -> int:
	var slots := max_board_pieces
	for gambit in gambits:
		slots += gambit.get_board_slot_bonus()
	return slots


# --- Special tiles ---

func get_tile_count() -> int:
	return tiles.size() + placed_tiles.size()


## Moves [param tile_index] of the unplaced tiles onto [param cell] of the board.
## The caller checks the cell is allowed.
func place_tile(tile_index: int, cell: Vector2i) -> bool:
	if tile_index < 0 or tile_index >= tiles.size() or placed_tiles.has(cell):
		return false
	
	placed_tiles[cell] = tiles[tile_index]
	tiles.remove_at(tile_index)
	return true


## Takes the tile on [param cell] back to the unplaced tiles.
func unplace_tile(cell: Vector2i) -> bool:
	if not placed_tiles.has(cell):
		return false
	
	tiles.append(placed_tiles[cell])
	placed_tiles.erase(cell)
	return true
