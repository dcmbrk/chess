class_name ChessMove
extends RefCounted

var from: Vector2i
var to: Vector2i


func _init(from_tile: Vector2i, to_tile: Vector2i) -> void:
	from = from_tile
	to = to_tile


func _to_string() -> String:
	return "%s -> %s" % [from, to]
