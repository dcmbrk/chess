## Between battles: buy pieces and gambits, reroll and upgrade the board.
class_name ShopScreen
extends Control

signal finished

@export_file("*.tscn") var next_scene := "res://scenes/arena/arena.tscn"

@onready var gambit_offers: HBoxContainer = %GambitOffers
@onready var offers: HBoxContainer = %Offers
@onready var reroll_button: Button = %RerollButton
@onready var upgrade_button: Button = %UpgradeButton
@onready var next_button: Button = %NextButton


func _ready() -> void:
	RunState.restock_shop()
	reroll_button.pressed.connect(_on_reroll_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	next_button.pressed.connect(_on_next_pressed)
	upgrade_button.mouse_entered.connect(_on_upgrade_button_mouse_entered)
	upgrade_button.mouse_exited.connect(Tooltip.hide_tooltip.bind(upgrade_button))
	_refresh()


func _refresh() -> void:
	_clear(gambit_offers)
	for i in RunState.SHOP_SIZE:
		gambit_offers.add_child(_create_gambit_offer(i))
	
	_clear(offers)
	for i in RunState.SHOP_SIZE:
		offers.add_child(_create_offer(i))
	
	reroll_button.text = "Reroll $%d" % RunState.REROLL_PRICE
	reroll_button.disabled = RunState.money < RunState.REROLL_PRICE
	
	if RunState.max_board_pieces >= RunState.MAX_BOARD_PIECES_LIMIT:
		upgrade_button.text = "Slots maxed"
	else:
		upgrade_button.text = "+1 Slot $%d" % RunState.get_upgrade_price()
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


func _create_gambit_offer(index: int) -> Button:
	var gambit := RunState.gambit_offers[index]
	var button := UiStyle.create_piece_button(null, "$%d" % gambit.price if gambit else "Sold")
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if gambit:
		button.icon = gambit.create_icon()
		Tooltip.attach_gambit(button, gambit)
	button.disabled = not RunState.can_buy_gambit(index)
	button.pressed.connect(_on_gambit_offer_pressed.bind(index))
	return button


func _on_offer_pressed(index: int) -> void:
	RunState.buy_offer(index)
	_refresh()


func _on_gambit_offer_pressed(index: int) -> void:
	RunState.buy_gambit(index)
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


func _on_upgrade_button_mouse_entered() -> void:
	var slots := RunState.max_board_pieces
	var body := "Max pieces on board: %d -> %d" % [slots, slots + 1]
	if slots >= RunState.MAX_BOARD_PIECES_LIMIT:
		body = "Max pieces on board: %d (limit)" % slots
	Tooltip.show_tooltip(upgrade_button, upgrade_button.get_global_rect(), "+1 Slot", "", body)


func _on_next_pressed() -> void:
	finished.emit()
	if next_scene:
		get_tree().change_scene_to_file(next_scene)
