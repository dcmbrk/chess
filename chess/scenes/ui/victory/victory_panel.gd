## Shown after beating the last boss of the run.
class_name VictoryPanel
extends CanvasLayer

signal closed

@onready var stats_label: Label = %StatsLabel
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	hide()
	main_menu_button.pressed.connect(_on_main_menu_pressed)


func open() -> void:
	stats_label.text = get_stats_text(RunState.money, RunState.pieces.size(), RunState.gambits.size())
	show()


static func get_stats_text(money: int, piece_count: int, gambit_count: int) -> String:
	return "$%d · %d pieces · %d gambits" % [money, piece_count, gambit_count]


func _on_main_menu_pressed() -> void:
	hide()
	closed.emit()
