## The special tiles' effects, like the original game: they trigger when a piece
## moves onto the tile and give the piece a status (see SpecialTileData.Effect).
class_name TileEffects
extends Node

@export var board: PlayArea
@export var bench: PlayArea
@export var turn_manager: TurnManager
@export var unit_mover: UnitMover
@export var unit_spawner: UnitSpawner
@export var player_team := UnitStats.Team.WHITE

## Each Phantom tile works once per battle.
var _used_phantom_tiles: Dictionary[Vector2i, bool] = {}


func _ready() -> void:
	unit_mover.unit_landed.connect(_on_unit_landed)
	turn_manager.turn_started.connect(_on_turn_started)


## The bench copy made by a Phantom tile, or null when the bench is full.
func spawn_phantom(unit: Unit) -> Unit:
	if bench.unit_grid.is_grid_full():
		return null
	var copy := unit_spawner.spawn_unit_at(unit.get_run_stats(), bench, bench.unit_grid.get_first_empty_tile())
	copy.is_temporary = true
	return copy


func _on_unit_landed(unit: Unit, tile: Vector2i) -> void:
	var special := board.unit_grid.special_tiles.get(tile) as SpecialTileData
	if not special:
		return
	
	var is_player := unit.stats.team == player_team
	match special.effect:
		SpecialTileData.Effect.PROTECTION:
			if is_player:
				unit.is_protected = true
		SpecialTileData.Effect.BENEDICTION:
			if is_player:
				unit.is_blessed = true
		SpecialTileData.Effect.HUNTER:
			if not is_player:
				unit.is_trapped = true
				unit.trap_served = false
		SpecialTileData.Effect.PHANTOM:
			if is_player and not unit.is_temporary and not _used_phantom_tiles.has(tile):
				_used_phantom_tiles[tile] = true
				spawn_phantom(unit)


func _on_turn_started(team: UnitStats.Team) -> void:
	for unit in board.unit_grid.get_all_units():
		# Protection lasted through the other team's turn.
		if unit.stats.team == team:
			unit.is_protected = false
		
		if unit.is_trapped:
			if unit.stats.team == team:
				# This is the turn the trapped unit skips.
				unit.trap_served = true
			elif unit.trap_served:
				unit.is_trapped = false
