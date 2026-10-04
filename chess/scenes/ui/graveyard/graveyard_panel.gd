class_name GraveyardPanel
extends CanvasLayer

signal closed

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
	var slot := UiStyle.create_piece_button(piece, "$%d" % RunState.REVIVE_PRICE)
	slot.disabled = not RunState.can_revive(index)
	slot.pressed.connect(_on_slot_pressed.bind(index))
	return slot


func _on_slot_pressed(index: int) -> void:
	RunState.revive_piece(index)
	_refresh()


func _on_next_pressed() -> void:
	hide()
	closed.emit()
