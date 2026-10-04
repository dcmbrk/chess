## During the preparation the player can hold the right mouse button on one of
## their pieces to sell it.
class_name UnitSeller
extends Node

signal unit_sold(unit: Unit, price: int)

const SELL_TINT := Color(1, 0.4, 0.4)

@export var preparation: PreparationPhase
@export var board: PlayArea
@export var bench: PlayArea
@export var hold_time := 0.6

var play_areas: Array[PlayArea] = []
var _held: Unit
var _held_time := 0.0


func _ready() -> void:
	play_areas.assign([board, bench].filter(func(area: PlayArea) -> bool: return area != null))
	var units := get_tree().get_nodes_in_group("units")
	for unit: Unit in units:
		setup_unit(unit)


func setup_unit(unit: Unit) -> void:
	unit.input_event.connect(_on_unit_input_event.bind(unit))
	unit.mouse_exited.connect(_on_unit_mouse_exited.bind(unit))


func _process(delta: float) -> void:
	if not _held:
		return
	
	_held_time += delta
	_held.modulate = Color.WHITE.lerp(SELL_TINT, clampf(_held_time / hold_time, 0.0, 1.0))
	if _held_time >= hold_time:
		sell(_held)


func _input(event: InputEvent) -> void:
	if _held and event.is_action_released("sell_unit"):
		cancel_hold()


func can_sell(unit: Unit) -> bool:
	return preparation.active \
			and unit.stats.team == preparation.player_team \
			and RunState.can_sell(RunState.pieces.find(unit.get_run_stats()))


## Starts selling [param unit]; it is sold after [member hold_time] unless canceled.
func start_hold(unit: Unit) -> void:
	if not can_sell(unit) or unit.drag_and_drop.dragging:
		return
	
	cancel_hold()
	_held = unit
	_held_time = 0.0


func cancel_hold() -> void:
	if is_instance_valid(_held):
		_held.modulate = Color.WHITE
	_held = null


## Sells [param unit] right away. Returns false if it can't be sold.
func sell(unit: Unit) -> bool:
	if not can_sell(unit):
		return false
	
	var piece := unit.get_run_stats()
	cancel_hold()
	
	for play_area in play_areas:
		for tile: Vector2i in play_area.unit_grid.units:
			if play_area.unit_grid.units[tile] == unit:
				play_area.unit_grid.remove_unit(tile)
	
	RunState.sell_piece(RunState.pieces.find(piece))
	unit_sold.emit(unit, piece.get_sell_price())
	Sfx.play("sell")
	unit.queue_free()
	return true


func _on_unit_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, unit: Unit) -> void:
	if event.is_action_pressed("sell_unit"):
		start_hold(unit)


func _on_unit_mouse_exited(unit: Unit) -> void:
	if unit == _held:
		cancel_hold()
