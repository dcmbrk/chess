class_name PrepPanel
extends CanvasLayer

signal go_pressed

@onready var pieces_label: Label = %PiecesLabel
@onready var go_button: Button = %GoButton


func _ready() -> void:
	go_button.pressed.connect(go_pressed.emit)


func update_pieces(count: int, max_count: int) -> void:
	pieces_label.text = "Pieces %d/%d" % [count, max_count]
	go_button.disabled = count == 0
