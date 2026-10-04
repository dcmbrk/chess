## Between battles: buy pieces, reroll, upgrade the board and sell from the Stock.
class_name ShopScreen
extends Control

signal finished

@export_file("*.tscn") var next_scene := "res://scenes/arena/arena.tscn"

var _held_stock_index := -1

@onready var offers: HBoxContainer = %Offers
@onready var stock: HBoxContainer = %Stock
@onready var reroll_button: Button = %RerollButton
@onready var upgrade_button: Button = %UpgradeButton
@onready var next_button: Button = %NextButton
@onready var hold_timer: Timer = %HoldTimer


func _ready() -> void:
	RunState.restock_shop()
	reroll_button.pressed.connect(_on_reroll_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	next_button.pressed.connect(_on_next_pressed)
	hold_timer.timeout.connect(_on_hold_timer_timeout)
	_refresh()


func _refresh() -> void:
	_clear(offers)
	for i in RunState.SHOP_SIZE:
		offers.add_child(_create_offer(i))
	
	_clear(stock)
	for i in RunState.pieces.size():
		stock.add_child(_create_stock_slot(i))
	
	reroll_button.text = "Reroll $%d" % RunState.REROLL_PRICE
	reroll_button.disabled = RunState.money < RunState.REROLL_PRICE
	
	if RunState.max_board_pieces >= RunState.MAX_BOARD_PIECES_LIMIT:
		upgrade_button.text = "Slots maxed"
	else:
		upgrade_button.text = "+1 Slot $%d" % RunState.get_upgrade_price()
	upgrade_button.tooltip_text = "Max pieces on board: %d" % RunState.max_board_pieces
	upgrade_button.disabled = not RunState.can_upgrade()


func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _create_offer(index: int) -> VBoxContainer:
	var offer := RunState.shop_offers[index]
	var locked := RunState.shop_locks[index]
	
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	
	var color := UiStyle.SLOT_SELECTED_COLOR if locked else UiStyle.SLOT_COLOR
	var buy_button := UiStyle.create_piece_button(offer, "$%d" % offer.price if offer else "Sold", color)
	buy_button.disabled = not RunState.can_buy(index)
	buy_button.pressed.connect(_on_offer_pressed.bind(index))
	box.add_child(buy_button)
	
	var lock_button := Button.new()
	lock_button.text = "Locked" if locked else "Lock"
	lock_button.add_theme_font_size_override("font_size", 4)
	lock_button.add_theme_stylebox_override("normal", UiStyle.create_flat_style(Color.TRANSPARENT, 0))
	lock_button.add_theme_stylebox_override("hover", UiStyle.create_flat_style(Color(1, 1, 1, 0.1), 0))
	lock_button.add_theme_stylebox_override("pressed", UiStyle.create_flat_style(Color.TRANSPARENT, 0))
	lock_button.add_theme_stylebox_override("disabled", UiStyle.create_flat_style(Color.TRANSPARENT, 0))
	lock_button.disabled = offer == null
	lock_button.pressed.connect(_on_lock_pressed.bind(index))
	box.add_child(lock_button)
	
	return box


func _create_stock_slot(index: int) -> Button:
	var piece := RunState.pieces[index]
	var slot := UiStyle.create_piece_button(piece, "+$%d" % piece.get_sell_price())
	slot.disabled = not RunState.can_sell(index)
	slot.button_down.connect(_on_stock_slot_down.bind(index))
	slot.button_up.connect(_on_stock_slot_up)
	return slot


func _on_offer_pressed(index: int) -> void:
	RunState.buy_offer(index)
	_refresh()


func _on_lock_pressed(index: int) -> void:
	RunState.toggle_lock(index)
	_refresh()


func _on_reroll_pressed() -> void:
	RunState.reroll_shop()
	_refresh()


func _on_upgrade_pressed() -> void:
	RunState.upgrade_max_board_pieces()
	_refresh()


func _on_stock_slot_down(index: int) -> void:
	_held_stock_index = index
	hold_timer.start()


func _on_stock_slot_up() -> void:
	_held_stock_index = -1
	hold_timer.stop()


func _on_hold_timer_timeout() -> void:
	if _held_stock_index == -1:
		return
	
	RunState.sell_piece(_held_stock_index)
	_held_stock_index = -1
	_refresh()


func _on_next_pressed() -> void:
	finished.emit()
	if next_scene:
		get_tree().change_scene_to_file(next_scene)
