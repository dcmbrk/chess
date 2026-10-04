## Tiny padlock toggling whether a shop offer is kept on reroll.
class_name LockButton
extends Button

const LOCKED_COLOR := Color("2f7a41")
## Like the original: always green, only the padlock opens or closes.
const UNLOCKED_COLOR := Color("3a8f4f")
const OUTLINE_COLOR := Color("0b0d18")
const GLYPH_COLOR := Color("f3e3c3")

var locked := false:
	set(value):
		locked = value
		queue_redraw()


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	# The default button styles have margins that would make it 8x8 at least.
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	custom_minimum_size = Vector2(5, 5)
	size = custom_minimum_size


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	draw_rect(box, OUTLINE_COLOR)
	draw_rect(box.grow(-0.25), LOCKED_COLOR if locked else UNLOCKED_COLOR)
	# Body and shackle; an open lock lifts its shackle.
	var lift := 0.0 if locked else 0.5
	draw_rect(Rect2(1.25, 2.5, 2.5, 1.75), GLYPH_COLOR)
	draw_rect(Rect2(1.5, 1.0 - lift, 0.5, 1.5), GLYPH_COLOR)
	draw_rect(Rect2(3.0, 1.0 - lift, 0.5, 1.5 if locked else 1.0), GLYPH_COLOR)
	draw_rect(Rect2(1.5, 0.75 - lift, 2.0, 0.5), GLYPH_COLOR)
