class_name MoveHighlighter
extends Node

@export var play_area: PlayArea
@export var hint_layer: TileMapLayer
@export var tile: Vector2i
## Optional: shows where a Stock unit can be put during a battle.
@export var unit_mover: UnitMover

## The hint layer has its own tile set (the selection frame art).
@onready var source_id := hint_layer.tile_set.get_source_id(0)


func _ready() -> void:
	var units := get_tree().get_nodes_in_group("units")
	for unit: Unit in units:
		setup_unit(unit)


func setup_unit(unit: Unit) -> void:
	unit.mouse_entered.connect(_on_unit_mouse_entered.bind(unit))
	unit.mouse_exited.connect(_on_unit_mouse_exited)
	unit.drag_and_drop.drag_started.connect(show_moves.bind(unit))
	unit.drag_and_drop.drag_canceled.connect(clear.unbind(1))
	unit.drag_and_drop.dropped.connect(clear.unbind(1))


func show_moves(unit: Unit) -> void:
	clear()
	if not Settings.move_hints:
		return

	var from := play_area.get_tile_from_global(unit.global_position)
	if not unit.stats:
		return
	if not play_area.is_tile_in_bounds(from):
		_show_deploy_tiles(unit)
		return

	# The unit may already be removed from the grid by UnitMover.
	var board := play_area.unit_grid.to_board_state()
	board.set_piece(from, unit.stats)

	for move in MoveRules.get_legal_moves(board, from):
		hint_layer.set_cell(move, source_id, tile)


func clear() -> void:
	hint_layer.clear()


func _is_any_unit_dragging() -> bool:
	return get_tree().get_first_node_in_group("dragging") != null


func _on_unit_mouse_entered(unit: Unit) -> void:
	if not _is_any_unit_dragging():
		show_moves(unit)


func _on_unit_mouse_exited() -> void:
	if not _is_any_unit_dragging():
		clear()


func _show_deploy_tiles(unit: Unit) -> void:
	if not unit_mover:
		return
	
	for board_tile: Vector2i in play_area.unit_grid.units:
		if unit_mover.can_deploy(unit, board_tile):
			hint_layer.set_cell(board_tile, source_id, tile)
