## The bought special tiles waiting to be placed. During the preparation: click a
## tile here, then an empty or occupied tile of your rows to place it. Click an
## empty board tile holding a special tile to take it back.
class_name TileTray
extends VBoxContainer

signal tiles_changed

@export var board: PlayArea
@export var preparation: PreparationPhase
@export var overlay: SpecialTilesOverlay

var selected_index := -1


func _ready() -> void:
	preparation.started.connect(refresh)
	preparation.battle_started.connect(_on_battle_started)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if not preparation.active or not click or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	
	var cell := board.get_hovered_tile()
	if not board.is_tile_in_bounds(cell):
		return
	
	var handled := false
	if selected_index >= 0:
		handled = place(cell)
	elif not board.unit_grid.is_tile_occupied(cell):
		# Occupied tiles are left to the unit drag and drop.
		handled = pick_up(cell)
	if handled:
		get_viewport().set_input_as_handled()


func select(index: int) -> void:
	selected_index = -1 if selected_index == index else index
	refresh()


func can_place_at(cell: Vector2i) -> bool:
	var grid := board.unit_grid
	return preparation.active \
			and preparation.is_in_player_zone(cell) \
			and not grid.special_tiles.has(cell) \
			and grid.forbidden_tiles.get(cell, -1) != preparation.player_team


func place(cell: Vector2i) -> bool:
	if selected_index < 0 or not can_place_at(cell):
		return false
	
	var tile := RunState.tiles[selected_index]
	RunState.place_tile(selected_index, cell)
	board.unit_grid.special_tiles[cell] = tile
	selected_index = -1
	_on_tiles_changed()
	return true


func pick_up(cell: Vector2i) -> bool:
	if not preparation.active or not board.unit_grid.special_tiles.has(cell):
		return false
	
	RunState.unplace_tile(cell)
	board.unit_grid.special_tiles.erase(cell)
	_on_tiles_changed()
	return true


func refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	visible = preparation.active and not RunState.tiles.is_empty()
	for i in RunState.tiles.size():
		var tile := RunState.tiles[i]
		var color := UiStyle.SLOT_SELECTED_COLOR if i == selected_index else UiStyle.SLOT_COLOR
		var button := UiStyle.create_piece_button(null, "", color)
		button.icon = tile.texture
		button.custom_minimum_size = Vector2(8, 8)
		button.pressed.connect(select.bind(i))
		Tooltip.attach(button, tile.display_name, "Click, then click a tile of your rows", tile.description)
		add_child(button)


func _on_tiles_changed() -> void:
	overlay.queue_redraw()
	refresh()
	tiles_changed.emit()


func _on_battle_started() -> void:
	selected_index = -1
	refresh()
