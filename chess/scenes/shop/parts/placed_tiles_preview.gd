## Draws the run's placed special tiles on the shop's board preview.
class_name PlacedTilesPreview
extends Node2D


func _draw() -> void:
	var cell := Arena.CELL_SIZE
	for tile in RunState.placed_tiles:
		draw_texture_rect(RunState.placed_tiles[tile].texture, Rect2(Vector2(tile) * cell, cell), false)
