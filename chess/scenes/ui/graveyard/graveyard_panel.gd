class_name GraveyardPanel
extends CanvasLayer

signal closed

const SLOT_COLOR := Color(0.93, 0.89, 0.78, 1)
const SLOT_HOVER_COLOR := Color(1, 0.97, 0.88, 1)
const SLOT_DISABLED_COLOR := Color(0.45, 0.43, 0.4, 1)
const SLOT_TEXT_COLOR := Color(0.55, 0.27, 0.3, 1)

@onready var slots: HBoxContainer = %Slots
@onready var next_button: Button = %NextButton


func _ready() -> void:
	hide()
	next_button.pressed.connect(_on_next_pressed)


func open() -> void:
	_refresh()
	show()


func _refresh() -> void:
	for slot in slots.get_children():
		slots.remove_child(slot)
		slot.queue_free()
	
	for i in RunState.graveyard.size():
		slots.add_child(_create_slot(i, RunState.graveyard[i]))


func _create_slot(index: int, piece: UnitStats) -> Button:
	var slot := Button.new()
	slot.icon = piece.create_icon()
	slot.text = "$%d" % RunState.REVIVE_PRICE
	slot.add_theme_font_size_override("font_size", 5)
	slot.add_theme_constant_override("h_separation", 0)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		slot.add_theme_color_override(state, SLOT_TEXT_COLOR)
	slot.add_theme_stylebox_override("normal", _create_slot_style(SLOT_COLOR))
	slot.add_theme_stylebox_override("pressed", _create_slot_style(SLOT_COLOR))
	slot.add_theme_stylebox_override("hover", _create_slot_style(SLOT_HOVER_COLOR))
	slot.add_theme_stylebox_override("focus", _create_slot_style(SLOT_HOVER_COLOR))
	slot.add_theme_stylebox_override("disabled", _create_slot_style(SLOT_DISABLED_COLOR))
	slot.disabled = not RunState.can_revive(index)
	slot.pressed.connect(_on_slot_pressed.bind(index))
	return slot


func _create_slot_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(1)
	return style


func _on_slot_pressed(index: int) -> void:
	RunState.revive_piece(index)
	_refresh()


func _on_next_pressed() -> void:
	hide()
	closed.emit()
