@tool
## The arena background: dark navy with faint blue piece shapes and a few bubbles.
## Always the same pattern thanks to the fixed seed.
class_name BackgroundSkin
extends Node2D

const SHAPE_TEXTURE := preload("res://assets/sprites/pieces/SPR_ChessPieces.png")
const SHAPE_SOURCE_SIZE := Vector2(40, 32)

@export var size := Vector2(160, 80)
@export var pattern_seed := 7:
	set(value):
		pattern_seed = value
		queue_redraw()
@export var base_color := Color("0a0a14")
@export var shape_color := Color(0.06, 0.2, 0.32, 0.55)
@export var bubble_color := Color(0.11, 0.33, 0.55, 0.9)
@export var shape_count := 14
@export var bubble_count := 9


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), base_color)
	
	var rng := RandomNumberGenerator.new()
	rng.seed = pattern_seed
	for i in shape_count:
		var source := Rect2(Vector2(rng.randi_range(0, 5), rng.randi_range(0, 1)) * SHAPE_SOURCE_SIZE, SHAPE_SOURCE_SIZE)
		var center := Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		var scale_factor := rng.randf_range(0.35, 0.8)
		draw_set_transform(center, rng.randf_range(-PI, PI), Vector2.ONE * scale_factor)
		draw_texture_rect_region(SHAPE_TEXTURE, Rect2(-SHAPE_SOURCE_SIZE / 2, SHAPE_SOURCE_SIZE), source, shape_color)
	draw_set_transform(Vector2.ZERO)
	
	for i in bubble_count:
		var center := Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y))
		draw_circle(center, rng.randf_range(0.5, 1.5), bubble_color)
