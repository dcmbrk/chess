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
var shop_offers: Array[UnitStats] = []
## Locked offers are kept when the shop is rerolled or restocked.
var shop_locks: Array[bool] = []
## Gambits for sale; null means the slot is empty or was bought.
var gambit_offers: Array[GambitData] = []
var gambits: Array[GambitData] = []
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
	shop_offers.clear()
	shop_offers.resize(SHOP_SIZE)
	shop_locks.clear()
	shop_locks.resize(SHOP_SIZE)
	gambit_offers.clear()
	gambit_offers.resize(SHOP_SIZE)
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

## Fills every unlocked piece slot and every gambit slot with new random offers.
func restock_shop() -> void:
	for i in SHOP_SIZE:
		if not shop_locks[i]:
			shop_offers[i] = WeightedRandom.pick(SHOP_POOL, SHOP_WEIGHTS, rng)
	
	gambit_offers.fill(null)
	for i in SHOP_SIZE:
		gambit_offers[i] = _pick_gambit_offer()


## A random gambit the player doesn't own and that isn't offered yet, or null.
func _pick_gambit_offer() -> GambitData:
	var candidates := GAMBIT_POOL.filter(func(gambit: GambitData) -> bool:
		return gambit not in gambits and gambit not in gambit_offers
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


func can_buy(index: int) -> bool:
	var offer := shop_offers[index]
	return offer != null and money >= offer.price and pieces.size() < MAX_PIECES


func buy_offer(index: int) -> bool:
	if not can_buy(index):
		return false
	
	money -= shop_offers[index].price
	pieces.append(shop_offers[index])
	shop_offers[index] = null
	shop_locks[index] = false
	return true


func toggle_lock(index: int) -> void:
	if shop_offers[index]:
		shop_locks[index] = not shop_locks[index]


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

func can_buy_gambit(index: int) -> bool:
	var offer := gambit_offers[index]
	return offer != null and money >= offer.price and gambits.size() < MAX_GAMBITS


func buy_gambit(index: int) -> bool:
	if not can_buy_gambit(index):
		return false
	
	money -= gambit_offers[index].price
	gambits.append(gambit_offers[index])
	gambit_offers[index] = null
	gambits_changed.emit()
	return true


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
