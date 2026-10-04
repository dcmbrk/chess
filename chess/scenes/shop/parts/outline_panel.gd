## A panel with a thin outline (see OutlineButton).
class_name OutlinePanel
extends Panel

@export var outline_color := Color("f3e3c3")
@export var outline_width := 0.375


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size).grow(-outline_width / 2), outline_color, false, outline_width)
