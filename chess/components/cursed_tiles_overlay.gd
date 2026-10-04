## Marks the CURSED tiles of the board.
class_name CursedTilesOverlay
extends Node2D

const TEXTURE := preload("res://assets/sprites/tiles/cursed_tile.png")

@export var unit_grid: UnitGrid


func _draw() -> void:
	var cell := Arena.CELL_SIZE
	for tile in unit_grid.forbidden_tiles:
		draw_texture_rect(TEXTURE, Rect2(Vector2(tile) * cell, cell), false)
