## Shared look of small UI elements built from code.
class_name UiStyle
extends RefCounted

const SLOT_COLOR := Color(0.93, 0.89, 0.78, 1)
const SLOT_HOVER_COLOR := Color(1, 0.97, 0.88, 1)
const SLOT_DISABLED_COLOR := Color(0.45, 0.43, 0.4, 1)
const SLOT_SELECTED_COLOR := Color(0.96, 0.8, 0.38, 1)
const SLOT_TEXT_COLOR := Color(0.55, 0.27, 0.3, 1)


static func create_flat_style(color: Color, margin := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(margin)
	return style


## A compact button showing a piece icon followed by [param text].
static func create_piece_button(piece: UnitStats, text: String, color := SLOT_COLOR) -> Button:
	var button := Button.new()
	button.icon = piece.create_icon() if piece else null
	button.text = text
	if piece:
		Tooltip.attach(button, piece.get_display_name(), "", piece.get_description())
	button.add_theme_font_size_override("font_size", 5)
	button.add_theme_constant_override("h_separation", 0)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, SLOT_TEXT_COLOR)
	button.add_theme_stylebox_override("normal", create_flat_style(color))
	button.add_theme_stylebox_override("pressed", create_flat_style(color))
	button.add_theme_stylebox_override("hover", create_flat_style(SLOT_HOVER_COLOR))
	button.add_theme_stylebox_override("focus", create_flat_style(SLOT_HOVER_COLOR))
	button.add_theme_stylebox_override("disabled", create_flat_style(SLOT_DISABLED_COLOR))
	return button
