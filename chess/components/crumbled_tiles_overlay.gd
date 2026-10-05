## Draws the fallen (crumbled) tiles as dark holes.
class_name CrumbledTilesOverlay
extends Node2D

const HOLE_COLOR := Color("05050a")
const RIM_COLOR := Color("2a2230")

@export var unit_grid: UnitGrid


func _draw() -> void:
	var cell := Arena.CELL_SIZE
	for tile in unit_grid.holes:
		var rect := Rect2(Vector2(tile) * cell, cell)
		draw_rect(rect, RIM_COLOR)
		draw_rect(rect.grow(-0.5), HOLE_COLOR)
