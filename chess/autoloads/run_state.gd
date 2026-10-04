## Data that lives for a whole run (survives scene reloads between battles).
extends Node

signal money_changed(money: int)

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
var rng := RandomNumberGenerator.new()
## How many pieces the player may place on the board.
var max_board_pieces := STARTING_MAX_BOARD_PIECES
## Pieces for sale; null means the slot was bought.
var shop_offers: Array[UnitStats] = []
## Locked offers are kept when the shop is rerolled or restocked.
var shop_locks: Array[bool] = []


func _ready() -> void:
	reset()


func add_money(amount: int) -> void:
	money += amount


func reset() -> void:
	money = STARTING_MONEY
	pieces = STARTING_PIECES.duplicate()
	graveyard.clear()
	stage = 1
	game = 1
	rng.randomize()
	max_board_pieces = STARTING_MAX_BOARD_PIECES
	shop_offers.clear()
	shop_offers.resize(SHOP_SIZE)
	shop_locks.clear()
	shop_locks.resize(SHOP_SIZE)


func is_boss_game() -> bool:
	return game == GAMES_PER_STAGE


## Moves to the next game. Returns true when the whole run is completed.
func advance() -> bool:
	game += 1
	if game > GAMES_PER_STAGE:
		game = 1
		stage += 1
	return stage > STAGE_COUNT


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

## Fills every unlocked slot with a new random piece.
func restock_shop() -> void:
	for i in SHOP_SIZE:
		if not shop_locks[i]:
			shop_offers[i] = WeightedRandom.pick(SHOP_POOL, SHOP_WEIGHTS, rng)


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
