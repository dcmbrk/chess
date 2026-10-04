class_name UnitMover
extends Node

signal unit_captured(unit: Unit, by: Unit)
## The player's pawn reached the last row; call [method finish_promotion] with one of [param options].
signal promotion_requested(unit: Unit, options: Array[Resource])

@export var play_areas: Array[PlayArea]
@export var board: PlayArea
@export var turn_manager: TurnManager
@export var player_team := UnitStats.Team.WHITE
@export var preparation: PreparationPhase
## Lets the player put Stock (bench) pieces on the board during a battle.
@export var allow_stock_in_battle := true
## Asks the player which piece their pawn becomes. When off, it becomes [member UnitStats.promotes_to].
@export var ask_player_promotion := false

var _pending_promotion: Unit


func _ready() -> void:
	var units := get_tree().get_nodes_in_group("units")
	for unit: Unit in units:
		_register_unit(unit)
		setup_unit(unit)
	
	if turn_manager:
		turn_manager.turn_started.connect(_update_draggable_units.unbind(1))
		turn_manager.battle_ended.connect(_update_draggable_units.unbind(1))
	if preparation:
		preparation.started.connect(_update_draggable_units)


func setup_unit(unit: Unit) -> void:
	unit.drag_and_drop.drag_started.connect(_on_unit_drag_started.bind(unit))
	unit.drag_and_drop.drag_canceled.connect(_on_unit_drag_canceled.bind(unit))
	unit.drag_and_drop.dropped.connect(_on_unit_dropped.bind(unit))
	unit.drag_and_drop.enabled = can_drag(unit)
	


## The player may only pick up their own pieces, during the preparation
## or on their own turn.
func can_drag(unit: Unit) -> bool:
	if not turn_manager and not preparation:
		return true
	if unit.stats.team != player_team:
		return false
	if _is_battle_active():
		return turn_manager.current_team == player_team and not is_waiting_for_promotion()
	return _is_preparing()


## Moves a unit that is on the board, following the chess rules.
## Returns false (and changes nothing) if the move is illegal.
func perform_board_move(unit: Unit, from: Vector2i, to: Vector2i) -> bool:
	# The unit may already be removed from the grid while it is dragged.
	var board_state := board.unit_grid.to_board_state()
	board_state.set_piece(from, unit.stats)
	
	if not turn_manager.is_legal_move(board_state, from, to):
		return false
	
	if board.unit_grid.units[from] == unit:
		board.unit_grid.remove_unit(from)
	
	var captured := board.unit_grid.units[to] as Unit
	if captured:
		board.unit_grid.remove_unit(to)
		unit_captured.emit(captured, unit)
		captured.queue_free()
		Sfx.play("capture")
		ScreenEffects.shake()
	else:
		Sfx.play("move")
	
	_move_unit(unit, board, to)
	var promotion := MoveRules.get_promotion(board_state, unit.stats, to)
	if promotion and _should_ask_promotion(unit):
		# The turn ends once the player picked the new piece.
		_pending_promotion = unit
		_update_draggable_units()
		promotion_requested.emit(unit, unit.stats.promotion_options)
		return true
	if promotion:
		unit.promote(promotion)
		Sfx.play("promote")
	
	turn_manager.end_turn(get_rules_board())
	return true


func is_waiting_for_promotion() -> bool:
	return _pending_promotion != null


func finish_promotion(choice: UnitStats) -> void:
	assert(is_waiting_for_promotion(), "No promotion to finish!")
	assert(choice in _pending_promotion.stats.promotion_options, "Not a promotion option!")
	
	_pending_promotion.promote(choice)
	_pending_promotion = null
	Sfx.play("promote")
	turn_manager.end_turn(get_rules_board())


func _should_ask_promotion(unit: Unit) -> bool:
	return ask_player_promotion and unit.stats.team == player_team \
			and not unit.stats.promotion_options.is_empty()


## Puts a Stock (bench) unit on an empty tile of the player's rows during a
## battle. It counts as the player's move. Returns false if it isn't allowed.
func perform_deploy(unit: Unit, to: Vector2i) -> bool:
	if not can_deploy(unit, to):
		return false
	
	for play_area in play_areas:
		if play_area == board:
			continue
		for tile: Vector2i in play_area.unit_grid.units:
			if play_area.unit_grid.units[tile] == unit:
				play_area.unit_grid.remove_unit(tile)
	
	_move_unit(unit, board, to)
	Sfx.play("move")
	turn_manager.end_turn(get_rules_board())
	return true


func can_deploy(unit: Unit, to: Vector2i) -> bool:
	return _can_use_stock() \
			and unit.stats.team == player_team \
			and turn_manager.current_team == player_team \
			and not is_waiting_for_promotion() \
			and _is_in_stock(unit) \
			and _is_free_deploy_tile(to)


## The board as the rules see it, including whether the player can still deploy.
func get_rules_board() -> BoardState:
	var board_state := board.unit_grid.to_board_state()
	board_state.can_deploy[player_team] = _can_deploy_any()
	return board_state


func _can_use_stock() -> bool:
	return allow_stock_in_battle and _is_battle_active() and preparation != null \
			and preparation.count_player_pieces() < preparation.max_pieces


func _is_in_stock(unit: Unit) -> bool:
	for play_area in play_areas:
		if play_area != board and unit in play_area.unit_grid.get_all_units():
			return true
	return false


func _is_free_deploy_tile(tile: Vector2i) -> bool:
	return preparation.is_in_player_zone(tile) \
			and not board.unit_grid.is_tile_occupied(tile) \
			and board.unit_grid.forbidden_tiles.get(tile, -1) != player_team


func _can_deploy_any() -> bool:
	if not _can_use_stock():
		return false
	
	var has_stock := false
	for play_area in play_areas:
		if play_area == board:
			continue
		for unit in play_area.unit_grid.get_all_units():
			has_stock = has_stock or unit.stats.team == player_team
	if not has_stock:
		return false
	
	for tile: Vector2i in board.unit_grid.units:
		if _is_free_deploy_tile(tile):
			return true
	return false


func _is_battle_active() -> bool:
	return turn_manager != null and turn_manager.active


func _is_preparing() -> bool:
	return preparation != null and preparation.active


func _update_draggable_units() -> void:
	for play_area in play_areas:
		for unit in play_area.unit_grid.get_all_units():
			unit.drag_and_drop.enabled = can_drag(unit)


func _register_unit(unit: Unit) -> void:
	var i := _get_play_area_for_position(unit.global_position)
	if i == -1:
		return
	
	var tile := play_areas[i].get_tile_from_global(unit.global_position)
	play_areas[i].unit_grid.add_unit(tile, unit)


func _set_highlighters(enabled: bool) -> void:
	for play_area: PlayArea in play_areas:
		play_area.tile_highlighter.enabled = enabled


func _get_play_area_for_position(global: Vector2) -> int:
	var dropped_area_index := -1
	
	for i in play_areas.size():
		var tile := play_areas[i].get_tile_from_global(global)
		if play_areas[i].is_tile_in_bounds(tile):
			dropped_area_index = i
	
	return dropped_area_index


func _reset_unit_to_starting_position(starting_position: Vector2, unit: Unit) -> void:
	var i := _get_play_area_for_position(starting_position)
	var tile := play_areas[i].get_tile_from_global(starting_position)
	
	unit.reset_after_dragging(starting_position)
	play_areas[i].unit_grid.add_unit(tile, unit)


func _move_unit(unit: Unit, play_area: PlayArea, tile: Vector2i) -> void:
	var from := unit.global_position
	play_area.unit_grid.add_unit(tile, unit)
	unit.global_position = play_area.get_global_from_tile(tile)
	unit.reparent(play_area.unit_grid)
	unit.slide_from(from)


func _on_unit_drag_started(unit: Unit) -> void:
	_set_highlighters(true)
	
	# During a battle the held unit stays in the grid so the rules still see it.
	if _is_battle_active():
		return
	
	var i := _get_play_area_for_position(unit.global_position)
	if i > -1:
		var tile := play_areas[i].get_tile_from_global(unit.global_position)
		play_areas[i].unit_grid.remove_unit(tile)


func _on_unit_drag_canceled(starting_position: Vector2, unit: Unit) -> void:
	_set_highlighters(false)
	_reset_unit_to_starting_position(starting_position, unit)


func _on_unit_dropped(starting_position: Vector2, unit: Unit) -> void:
	_set_highlighters(false)

	var old_area_index := _get_play_area_for_position(starting_position)
	var drop_area_index := _get_play_area_for_position(unit.get_global_mouse_position())
	
	if drop_area_index == -1:
		_reset_unit_to_starting_position(starting_position, unit)
		return

	var old_area := play_areas[old_area_index]
	var old_tile := old_area.get_tile_from_global(starting_position)
	var new_area := play_areas[drop_area_index]
	var new_tile := new_area.get_hovered_tile()
	
	if _is_battle_active() and (old_area == board or new_area == board):
		var done := false
		if unit.stats.team == player_team and new_area == board:
			if old_area == board:
				done = perform_board_move(unit, old_tile, new_tile)
			else:
				done = perform_deploy(unit, new_tile)
		if not done:
			_reset_unit_to_starting_position(starting_position, unit)
		return
	
	if _is_preparing() and (old_area == board or new_area == board):
		var swapped := new_area.unit_grid.units[new_tile] as Unit
		if not preparation.can_drop(unit, old_area == board, new_area == board, new_tile, swapped):
			_reset_unit_to_starting_position(starting_position, unit)
			return
	
	if new_area.unit_grid.is_tile_occupied(new_tile):
		var old_unit: Unit = new_area.unit_grid.units[new_tile]
		new_area.unit_grid.remove_unit(new_tile)
		_move_unit(old_unit, old_area, old_tile)
	
	_move_unit(unit, new_area, new_tile)
	Sfx.play("move")
