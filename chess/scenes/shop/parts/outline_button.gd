## A button with a thin outline: StyleBoxFlat borders are whole game pixels
## (8 screen pixels), too thick for the shop's cards.
class_name OutlineButton
extends Button

@export var outline_color := Color("f3e3c3")
@export var outline_width := 0.375


func _draw() -> void:
	# Script _draw runs after the button drew itself, so this lands on top.
	draw_rect(Rect2(Vector2.ZERO, size).grow(-outline_width / 2), outline_color, false, outline_width)
