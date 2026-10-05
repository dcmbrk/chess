## The bar under the board during a battle, like the original game:
## Crumble Mode countdown, Wait (skip the turn) and whose turn it is.
class_name BattleBar
extends Control

signal wait_pressed

const MAX_DOTS := 5
const DOT_ON := Color("f3e3c3")
const DOT_OFF := Color(0.95, 0.89, 0.76, 0.2)

@onready var crumble_label: Label = %CrumbleLabel
@onready var dots: HBoxContainer = %Dots
@onready var wait_button: Button = %WaitButton
@onready var wait_count: Label = %WaitCount
@onready var turn_label: Label = %TurnLabel


func _ready() -> void:
	wait_button.pressed.connect(wait_pressed.emit)
	for i in MAX_DOTS:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(1, 1)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots.add_child(dot)
	Tooltip.attach(crumble_label, "Crumble Mode", "", "When the dots run out, a tile of the outer ring falls every turn.")
	Tooltip.attach(wait_button, "Wait", "", "Skip your turn.")


## One dot per remaining round (two turns), at most MAX_DOTS.
static func get_dot_count(turns_left: int) -> int:
	return mini(MAX_DOTS, ceili(turns_left / 2.0))


func set_countdown(turns_left: int) -> void:
	var lit := get_dot_count(turns_left)
	for i in dots.get_child_count():
		(dots.get_child(i) as ColorRect).color = DOT_ON if i < lit else DOT_OFF
	crumble_label.text = "Crumbling!" if turns_left == 0 else "Crumble"


func set_waits(left: int, max_waits: int, can_wait: bool) -> void:
	wait_count.text = "%d/%d" % [left, max_waits]
	wait_button.disabled = not can_wait


func show_turn(is_player_turn: bool) -> void:
	turn_label.text = "Your turn!" if is_player_turn else "Enemy turn"
