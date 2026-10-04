## Small dark tag under a shop item: "$4", "Sold", ...
class_name PriceTag
extends Label

const BACKGROUND := Color("5a2a2e")
const TEXT_COLOR := Color("f3e3c3")

@export var background := BACKGROUND:
	set(value):
		background = value
		if has_theme_stylebox_override("normal"):
			(get_theme_stylebox("normal") as StyleBoxFlat).bg_color = value


func _init(tag_text := "", tag_color := BACKGROUND) -> void:
	text = tag_text
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", 3)
	add_theme_color_override("font_color", TEXT_COLOR)
	var style := StyleBoxFlat.new()
	style.bg_color = tag_color
	style.content_margin_left = 0.5
	style.content_margin_right = 0.5
	style.anti_aliasing = false
	add_theme_stylebox_override("normal", style)
	background = tag_color


var _fit_width := -1.0


## Spans a [param width] wide slot (1 px inset) with the text centered.
## A Label first measures its text with the default font size and only later
## with ours, and a Control never shrinks back on its own: refit on every change.
func fit(width: float, top: float) -> void:
	_fit_width = width - 2
	position = Vector2(1, top)
	if not minimum_size_changed.is_connected(_apply_fit):
		minimum_size_changed.connect(_apply_fit)
	_apply_fit()


func _apply_fit() -> void:
	var minimum := get_combined_minimum_size()
	size = Vector2(maxf(_fit_width, minimum.x), minimum.y)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size).grow(-0.125), TEXT_COLOR, false, 0.25)
