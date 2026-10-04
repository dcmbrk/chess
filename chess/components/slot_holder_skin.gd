@tool
## Draws a vertical holder (the Stock bench or the relic column) with a dot for each slot.
class_name SlotHolderSkin
extends Node2D

const CELL := 8.0
## How far the panel reaches around the slots.
const PADDING := 2.0
const DOT_RADIUS := 1.0
## Border, corner and shadow sizes are fractions of a game pixel: the game is drawn at
## the window's resolution, so a thin border looks like the moodboard instead of a
## chunky 8 screen pixel step. 0.25 stays sharp when the game is scaled 4x or 8x.
const BORDER := 0.25
const SHADOW_WIDTH := 0.5

@export var slots := 6:
	set(value):
		slots = value
		queue_redraw()
@export var panel_color := Color("f6efc6")
@export var border_color := Color("0b0d18")
## Thick edge on the right side; transparent for none.
@export var shadow_color := Color("8a5251")
@export var dot_color := Color("0b0d18")


func _draw() -> void:
	# Plain rectangles only: a StyleBoxFlat anti-aliases its edges over a whole game pixel.
	var panel := get_panel_rect()
	_draw_rounded_rect(panel.grow(BORDER), border_color)
	draw_rect(panel, panel_color)
	
	if shadow_color.a > 0:
		draw_rect(get_shadow_rect(), shadow_color)
	
	for i in slots:
		draw_circle(get_slot_center(i), DOT_RADIUS, dot_color)


## A rectangle with its corners cut by BORDER, which reads as a slightly rounded corner.
func _draw_rounded_rect(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position.x + BORDER, rect.position.y, rect.size.x - BORDER * 2, rect.size.y), color)
	draw_rect(Rect2(rect.position.x, rect.position.y + BORDER, rect.size.x, rect.size.y - BORDER * 2), color)


## Along the right edge, stopping short of the corners.
func get_shadow_rect() -> Rect2:
	var panel := get_panel_rect()
	return Rect2(panel.end.x - SHADOW_WIDTH, panel.position.y + BORDER, SHADOW_WIDTH, panel.size.y - BORDER * 2)


func get_panel_rect() -> Rect2:
	return Rect2(-PADDING, -PADDING, CELL + PADDING * 2, slots * CELL + PADDING * 2)


func get_slot_center(index: int) -> Vector2:
	return Vector2(CELL / 2, CELL / 2 + index * CELL)
