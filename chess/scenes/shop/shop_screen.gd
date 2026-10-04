## Between battles, laid out like the original game's shop:
## - top row: Reroll and three items bought directly (gambits on red cards, pieces
##   on blue cards), each with a lock keeping it on reroll;
## - middle row: three tokens; buying one rolls random rewards and the player keeps
##   one in a popup;
## - bottom row: the board upgrade. NEXT! below the panel.
## Left of the panel: the Stock, a board preview and the next battle.
class_name ShopScreen
extends Control

signal finished

const CREAM := Color("f3e3c3")
const ROSE := Color("a8535a")
const GAMBIT_CARD := Color("b8636a")
const PIECE_CARD := Color("3d5596")
const TOKEN_CARD := Color("3d5596")
const TAG_DARK := Color("5e2328")
const TAG_BLUE := Color("2f3f72")
const CARD_SIZE := Vector2(11, 11)
## Top-left corners of the cards, in screen (game) pixels.
const ITEM_CARD_POSITIONS: Array[Vector2] = [Vector2(92, 18), Vector2(107, 18), Vector2(122, 18)]
const TOKEN_CARD_POSITIONS: Array[Vector2] = [Vector2(87, 37), Vector2(100, 37), Vector2(113, 37)]

@export_file("*.tscn") var next_scene := "res://scenes/arena/arena.tscn"

## Rebuilt by every refresh, in slot order.
var item_buttons: Array[Button] = []
var lock_buttons: Array[LockButton] = []
var item_tags: Array[PriceTag] = []
var token_buttons: Array[Button] = []
var token_tags: Array[PriceTag] = []
var choice_buttons: Array[Button] = []

@onready var slots: Control = %Slots
@onready var reroll_button: Button = %RerollButton
@onready var reroll_tag: PriceTag = %RerollTag
@onready var upgrade_label: Label = %UpgradeLabel
@onready var upgrade_count: Label = %UpgradeCount
@onready var upgrade_button: Button = %UpgradeButton
@onready var upgrade_tag: PriceTag = %UpgradeTag
@onready var next_button: Button = %NextButton
@onready var stock_icons: Control = %StockIcons
@onready var info_title: Label = %InfoTitle
@onready var info_body: Label = %InfoBody
@onready var choice_panel: Control = %ChoicePanel
@onready var choice_title: Label = %ChoiceTitle
@onready var choice_options: HBoxContainer = %ChoiceOptions


func _ready() -> void:
	RunState.restock_shop()
	reroll_button.pressed.connect(_on_reroll_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	next_button.pressed.connect(_on_next_pressed)
	upgrade_button.mouse_entered.connect(_on_upgrade_button_mouse_entered)
	upgrade_button.mouse_exited.connect(Tooltip.hide_tooltip.bind(upgrade_button))
	reroll_tag.fit(12, 24.5)
	reroll_tag.position.x += 77
	upgrade_tag.fit(14, 60.5)
	upgrade_tag.position.x += 111
	_refresh()


func _refresh() -> void:
	for child in slots.get_children():
		slots.remove_child(child)
		child.queue_free()
	_build_item_cards()
	_build_token_cards()
	_build_stock_icons()
	
	reroll_tag.text = "$%d" % RunState.REROLL_PRICE
	reroll_button.disabled = RunState.money < RunState.REROLL_PRICE
	
	upgrade_count.text = "%d/%d" % [RunState.max_board_pieces, RunState.MAX_BOARD_PIECES_LIMIT]
	var maxed := RunState.max_board_pieces >= RunState.MAX_BOARD_PIECES_LIMIT
	upgrade_tag.text = "Max" if maxed else "$%d" % RunState.get_upgrade_price()
	upgrade_button.disabled = not RunState.can_upgrade()
	
	next_button.disabled = not RunState.pending_choices.is_empty()
	_show_next_battle()
	_show_choices()


func _build_item_cards() -> void:
	item_buttons.clear()
	lock_buttons.clear()
	item_tags.clear()
	
	for i in RunState.SHOP_SIZE:
		var item := RunState.item_offers[i]
		var origin := ITEM_CARD_POSITIONS[i]
		var card := _create_card(origin, PIECE_CARD if item is UnitStats else GAMBIT_CARD)
		card.disabled = not RunState.can_buy_item(i)
		if item is GambitData:
			card.icon = (item as GambitData).create_icon()
			Tooltip.attach_gambit(card, item)
		elif item is UnitStats:
			card.icon = (item as UnitStats).create_icon()
			Tooltip.attach(card, item.get_display_name(), "Piece", item.get_description())
		card.pressed.connect(_on_item_pressed.bind(i))
		item_buttons.append(card)
		
		var lock := LockButton.new()
		lock.position = origin - Vector2(2, 2)
		lock.locked = RunState.item_locks[i]
		lock.disabled = item == null
		lock.pressed.connect(_on_lock_pressed.bind(i))
		slots.add_child(lock)
		lock_buttons.append(lock)
		
		item_tags.append(_create_tag("$%d" % item.price if item else "Sold", origin, TAG_DARK))


func _build_token_cards() -> void:
	token_buttons.clear()
	token_tags.clear()
	
	for i in RunState.SHOP_SIZE:
		var token := RunState.token_offers[i]
		var origin := TOKEN_CARD_POSITIONS[i]
		var card := _create_card(origin, TOKEN_CARD)
		card.disabled = not RunState.can_buy_token(i)
		if token:
			card.icon = token.create_icon()
			Tooltip.attach(card, token.display_name, "Token", token.description, Tooltip.RARITY_COLORS[GambitData.Rarity.RARE])
		card.pressed.connect(_on_token_pressed.bind(i))
		token_buttons.append(card)
		token_tags.append(_create_tag("$%d" % token.price if token else "Sold", origin, TAG_BLUE))


## A square card with a thin cream outline showing an 8 px icon.
func _create_card(origin: Vector2, color: Color) -> Button:
	var card := OutlineButton.new()
	card.position = origin
	card.size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_theme_constant_override("icon_max_width", 8)
	card.add_theme_stylebox_override("normal", _card_style(color))
	card.add_theme_stylebox_override("pressed", _card_style(color))
	card.add_theme_stylebox_override("focus", _card_style(color))
	card.add_theme_stylebox_override("hover", _card_style(color.lightened(0.15)))
	card.add_theme_stylebox_override("disabled", _card_style(color.darkened(0.35)))
	slots.add_child(card)
	return card


## The price tag overlapping the bottom of a card, like the original.
func _create_tag(tag_text: String, card_origin: Vector2, color: Color) -> PriceTag:
	var tag := PriceTag.new(tag_text, color)
	slots.add_child(tag)
	tag.fit(CARD_SIZE.x - 2, card_origin.y + CARD_SIZE.y - 2)
	tag.position.x += card_origin.x + 1
	return tag


static func _card_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(1.5)
	style.anti_aliasing = false
	return style


func _build_stock_icons() -> void:
	for child in stock_icons.get_children():
		stock_icons.remove_child(child)
		child.queue_free()
	for i in RunState.pieces.size():
		var piece := RunState.pieces[i]
		var icon := TextureRect.new()
		# Expand mode first: otherwise the 32 px texture forces its own size.
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture = piece.create_icon()
		icon.position = Vector2(0, i * Arena.CELL_SIZE.y)
		icon.size = Arena.CELL_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_PASS
		Tooltip.attach(icon, piece.get_display_name(), "In your Stock", piece.get_description())
		stock_icons.add_child(icon)


## Names the boss only when the next battle is the boss battle.
## (Stage and game are already on the HUD.)
func _show_next_battle() -> void:
	var boss_next := RunState.is_boss_game() and RunState.boss != null
	info_title.text = RunState.boss.display_name if boss_next else "Prepare your strategy!"
	info_body.text = RunState.boss.description if boss_next else ""
	info_body.visible = boss_next


## The popup of a bought token: keep one of its rolled rewards.
func _show_choices() -> void:
	for child in choice_options.get_children():
		choice_options.remove_child(child)
		child.queue_free()
	choice_buttons.clear()
	
	choice_panel.visible = not RunState.pending_choices.is_empty()
	for i in RunState.pending_choices.size():
		var reward := RunState.pending_choices[i]
		var option := UiStyle.create_piece_button(null, "")
		option.custom_minimum_size = Vector2(14, 14)
		option.add_theme_constant_override("icon_max_width", 10)
		if reward is UnitStats:
			option.icon = (reward as UnitStats).create_icon()
			Tooltip.attach(option, reward.get_display_name(), "Piece", reward.get_description())
		elif reward is SpecialTileData:
			option.icon = (reward as SpecialTileData).texture
			Tooltip.attach(option, reward.display_name, "Tile", reward.description)
		elif reward is GambitData:
			option.icon = (reward as GambitData).create_icon()
			Tooltip.attach_gambit(option, reward)
		option.pressed.connect(_on_choice_pressed.bind(i))
		choice_options.add_child(option)
		choice_buttons.append(option)


func _on_item_pressed(index: int) -> void:
	if RunState.buy_item(index):
		Sfx.play("buy")
	Tooltip.hide_tooltip()
	_refresh()


func _on_token_pressed(index: int) -> void:
	var token := RunState.token_offers[index]
	if not RunState.buy_token(index).is_empty():
		Sfx.play("buy")
		choice_title.text = token.display_name
	Tooltip.hide_tooltip()
	_refresh()


func _on_choice_pressed(index: int) -> void:
	if RunState.claim_choice(index):
		Sfx.play("promote")
	Tooltip.hide_tooltip()
	_refresh()


func _on_lock_pressed(index: int) -> void:
	RunState.toggle_lock(index)
	_refresh()


func _on_reroll_pressed() -> void:
	RunState.reroll_shop()
	_refresh()


func _on_upgrade_pressed() -> void:
	if RunState.upgrade_max_board_pieces():
		Sfx.play("buy")
	_refresh()


func _on_upgrade_button_mouse_entered() -> void:
	var slots_now := RunState.max_board_pieces
	var body := "Max pieces on board: %d -> %d" % [slots_now, slots_now + 1]
	if slots_now >= RunState.MAX_BOARD_PIECES_LIMIT:
		body = "Max pieces on board: %d (limit)" % slots_now
	Tooltip.show_tooltip(upgrade_button, upgrade_button.get_global_rect(), "Upgrade", "", body)


func _on_next_pressed() -> void:
	Tooltip.hide_tooltip()
	finished.emit()
	if next_scene:
		get_tree().change_scene_to_file(next_scene)
