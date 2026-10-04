## Data that lives for a whole run (survives scene reloads between battles).
extends Node

signal money_changed(money: int)

const STARTING_MONEY := 0

var money := STARTING_MONEY:
	set(value):
		money = value
		money_changed.emit(money)


func add_money(amount: int) -> void:
	money += amount


func reset() -> void:
	money = STARTING_MONEY
