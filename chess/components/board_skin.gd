@tool
## Draws the chess board: checkered tiles, a dark frame and the A-E / 1-5 labels.
## The board's TileMapLayer is only used for tile coordinates.
class_name BoardSkin
extends Node2D

const CELL := 8.0
const LABEL_FONT_SIZE := 5
## Room for the labels on the left and below the tiles.
const LABEL_MARGIN := 7.0

@export var size := Vector2i(5, 5):
	set(value):
		size = value
		queue_redraw()
@export var light_color := Color("e4c39e")
@export var dark_color := Color("8a4a4a")
@export var frame_color := Color("0b0d18")
@export var label_color := Color("f3e3c3")


func _draw() -> void:
	var tiles_rect := Rect2(Vector2.ZERO, Vector2(size) * CELL)
	var frame := Rect2(tiles_rect.position - Vector2(LABEL_MARGIN, 1), tiles_rect.size + Vector2(LABEL_MARGIN + 1, LABEL_MARGIN + 1))
	draw_rect(frame, frame_color)
	
	for x in size.x:
		for y in size.y:
			draw_rect(Rect2(Vector2(x, y) * CELL, Vector2(CELL, CELL)), get_tile_color(Vector2i(x, y)))
	
	var font := ThemeDB.fallback_font
	for y in size.y:
		var pos := Vector2(-LABEL_MARGIN, y * CELL + 6)
		draw_string(font, pos, get_row_label(y), HORIZONTAL_ALIGNMENT_CENTER, LABEL_MARGIN - 1, LABEL_FONT_SIZE, label_color)
	for x in size.x:
		var pos := Vector2(x * CELL, size.y * CELL + 6)
		draw_string(font, pos, get_column_label(x), HORIZONTAL_ALIGNMENT_CENTER, CELL, LABEL_FONT_SIZE, label_color)


## The top-left tile is light, like in the moodboard.
func get_tile_color(tile: Vector2i) -> Color:
	return light_color if (tile.x + tile.y) % 2 == 0 else dark_color


## Rows are numbered from the player's side: the bottom row is 1.
func get_row_label(y: int) -> String:
	return str(size.y - y)


func get_column_label(x: int) -> String:
	return String.chr("A".unicode_at(0) + x)
