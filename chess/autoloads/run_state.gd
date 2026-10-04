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
