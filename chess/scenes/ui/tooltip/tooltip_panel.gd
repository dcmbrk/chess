## The game's one tooltip (autoload "Tooltip"): a title, an optional colored
## subtitle and an optional description, shown above whatever is hovered.
extends CanvasLayer

const GAP := 1.0
## Descriptions wider than this wrap onto several lines.
const MAX_BODY_WIDTH := 64.0
const RARITY_COLORS := {
	GambitData.Rarity.COMMON: Color(0.75, 0.73, 0.68),
	GambitData.Rarity.RARE: Color(0.45, 0.65, 0.95),
	GambitData.Rarity.EPIC: Color(0.8, 0.5, 0.95),
}
const SUBTITLE_COLOR := Color(0.96, 0.8, 0.38)

var _owner: Node
var _target_rect: Rect2

@onready var panel: PanelContainer = %Panel
@onready var title: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var body: Label = %Body


func _ready() -> void:
	panel.hide()


func _process(_delta: float) -> void:
	# The hovered node may be freed without a mouse_exited signal.
	if panel.visible and not is_instance_valid(_owner):
		hide_tooltip()


## Shows the tooltip above [param target_rect] (global, in pixels) until
## [method hide_tooltip] is called or [param owner_node] is freed.
func show_tooltip(owner_node: Node, target_rect: Rect2, title_text: String, subtitle_text := "", body_text := "", subtitle_color := SUBTITLE_COLOR) -> void:
	_owner = owner_node
	_target_rect = target_rect
	
	title.text = title_text
	subtitle.text = subtitle_text
	subtitle.visible = not subtitle_text.is_empty()
	subtitle.add_theme_color_override("font_color", subtitle_color)
	body.text = body_text
	body.visible = not body_text.is_empty()
	_fit_body_width()
	
	panel.show()
	panel.reset_size()
	panel.position = get_tooltip_position(target_rect, panel.get_combined_minimum_size(), panel.get_viewport_rect().size)


func hide_tooltip(owner_node: Node = null) -> void:
	if owner_node and owner_node != _owner:
		return
	_owner = null
	panel.hide()


func is_showing() -> bool:
	return panel.visible


## Above the target and centered on it; below when there is no room above.
## Always kept inside the screen.
static func get_tooltip_position(target: Rect2, tooltip_size: Vector2, screen_size: Vector2) -> Vector2:
	var pos := Vector2(target.get_center().x - tooltip_size.x / 2, target.position.y - tooltip_size.y - GAP)
	if pos.y < 0:
		pos.y = target.end.y + GAP
	# Whole pixels keep the pixel font sharp.
	return pos.clamp(Vector2.ZERO, (screen_size - tooltip_size).max(Vector2.ZERO)).floor()


func _fit_body_width() -> void:
	body.autowrap_mode = TextServer.AUTOWRAP_OFF
	body.custom_minimum_size.x = 0
	var font := body.get_theme_font("font")
	var width := font.get_string_size(body.text, HORIZONTAL_ALIGNMENT_LEFT, -1, body.get_theme_font_size("font_size")).x
	if width > MAX_BODY_WIDTH:
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size.x = MAX_BODY_WIDTH


# --- Helpers for common tooltips ---

## Shows [param gambit]'s tooltip while [param control] is hovered.
func attach_gambit(control: Control, gambit: GambitData) -> void:
	attach(control, gambit.display_name, GambitData.Rarity.keys()[gambit.rarity].capitalize(),
			gambit.description, RARITY_COLORS[gambit.rarity])


## Shows a tooltip while [param control] is hovered.
func attach(control: Control, title_text: String, subtitle_text := "", body_text := "", subtitle_color := SUBTITLE_COLOR) -> void:
	control.mouse_entered.connect(func() -> void:
		show_tooltip(control, control.get_global_rect(), title_text, subtitle_text, body_text, subtitle_color)
	)
	control.mouse_exited.connect(hide_tooltip.bind(control))
