## Draws diagonal stripes over the enemy rows during the preparation phase.
class_name EnemyZoneOverlay
extends Node2D

@export var rows := 3
@export var columns := 5
@export var tint := Color(0, 0, 0, 0.25)
@export var stripe_color := Color(0, 0, 0, 0.35)

const STRIPE_SPACING := 4.0


func _draw() -> void:
	var cell := Arena.CELL_SIZE

	for x in columns:
		for y in rows:
			var origin := Vector2(x, y) * cell
			draw_rect(Rect2(origin, cell), tint)
			# Stripes line up across tiles because the cell size is a multiple of the spacing.
			draw_line(origin + Vector2(0, STRIPE_SPACING), origin + Vector2(STRIPE_SPACING, 0), stripe_color)
			draw_line(origin + Vector2(0, cell.y), origin + Vector2(cell.x, 0), stripe_color)
			draw_line(origin + Vector2(STRIPE_SPACING, cell.y), origin + Vector2(cell.x, STRIPE_SPACING), stripe_color)
