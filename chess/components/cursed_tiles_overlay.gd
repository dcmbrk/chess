## Marks the CURSED tiles of the board with a purple cross.
class_name CursedTilesOverlay
extends Node2D

const TINT := Color(0.45, 0.15, 0.55, 0.45)
const CROSS_COLOR := Color(0.75, 0.35, 0.9, 0.9)

@export var unit_grid: UnitGrid


func _draw() -> void:
	var cell := Arena.CELL_SIZE
	for tile in unit_grid.forbidden_tiles:
		var rect := Rect2(Vector2(tile) * cell, cell)
		draw_rect(rect, TINT)
		draw_line(rect.position + Vector2(1, 1), rect.end - Vector2(1, 1), CROSS_COLOR)
		draw_line(Vector2(rect.end.x - 1, rect.position.y + 1), Vector2(rect.position.x + 1, rect.end.y - 1), CROSS_COLOR)
