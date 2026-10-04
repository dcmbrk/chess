## Lets the player pick what their pawn becomes on the last row.
class_name PromotionPanel
extends CanvasLayer

signal chosen(piece: UnitStats)

@onready var options: HBoxContainer = %Options


func _ready() -> void:
	hide()


func open(_unit: Unit, pieces: Array[Resource]) -> void:
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()
	
	for piece: UnitStats in pieces:
		var button := UiStyle.create_piece_button(piece, "")
		button.pressed.connect(_on_option_pressed.bind(piece))
		options.add_child(button)
	
	show()


func _on_option_pressed(piece: UnitStats) -> void:
	hide()
	Tooltip.hide_tooltip()
	chosen.emit(piece)
