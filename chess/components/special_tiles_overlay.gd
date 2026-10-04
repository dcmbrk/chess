## Draws the special tiles placed on the board, under the pieces.
class_name SpecialTilesOverlay
extends Node2D

@export var unit_grid: UnitGrid


func _draw() -> void:
	var cell := Arena.CELL_SIZE
	for tile in unit_grid.special_tiles:
		draw_texture_rect(unit_grid.special_tiles[tile].texture, Rect2(Vector2(tile) * cell, cell), false)
