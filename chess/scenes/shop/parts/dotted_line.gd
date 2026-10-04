## A row of small dots, the separator of the original shop.
class_name DottedLine
extends Node2D

@export var length := 60.0
@export var spacing := 1.5
@export var dot_size := 0.5
@export var color := Color(0.95, 0.88, 0.75, 0.45)


func _draw() -> void:
	var x := 0.0
	while x <= length:
		draw_rect(Rect2(x, 0, dot_size, dot_size), color)
		x += spacing
