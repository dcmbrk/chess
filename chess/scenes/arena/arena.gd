class_name Arena
extends Node2D

const CELL_SIZE := Vector2(8, 8)
const HALF_CELL_SIZE := Vector2(4, 4)
const QUARTER_CELL_SIZE := Vector2(2, 2)
const PIECE_WHEELS_SCENE := "res://scenes/piece_wheels/piece_wheels.tscn"

## The enemies of this battle. Picked from RunState when left empty.
@export var encounter: EncounterData

@onready var unit_mover: UnitMover = $UnitMover
@onready var unit_spawner: UnitSpawner = $UnitSpawner
@onready var move_highlighter: MoveHighlighter = $MoveHighlighter
@onready var turn_manager: TurnManager = $TurnManager
@onready var board: PlayArea = $Board
@onready var battle_result: BattleResult = $BattleResult
@onready var preparation: PreparationPhase = $PreparationPhase
@onready var prep_panel: PrepPanel = $PrepPanel
@onready var enemy_zone_overlay: EnemyZoneOverlay = $Board/EnemyZoneOverlay
@onready var graveyard_panel: GraveyardPanel = $GraveyardPanel

var captured_enemies := 0
var outcome: GameRules.Outcome

func _ready() -> void:
	unit_spawner.unit_spawned.connect(unit_mover.setup_unit)
	unit_spawner.unit_spawned.connect(move_highlighter.setup_unit)
	unit_mover.unit_captured.connect(_on_unit_captured)
	turn_manager.battle_ended.connect(_on_battle_ended)
	battle_result.closed.connect(_on_battle_result_closed)
	preparation.pieces_changed.connect(prep_panel.update_pieces)
	preparation.battle_started.connect(_on_battle_started)
	prep_panel.go_pressed.connect(preparation.start_battle)
	graveyard_panel.closed.connect(get_tree().reload_current_scene)
	
	if not encounter:
		encounter = RunState.pick_encounter()
	for tile in encounter.pieces:
		unit_spawner.spawn_unit_at(encounter.pieces[tile], board, tile)
	
	for piece in RunState.pieces:
		unit_spawner.spawn_unit(piece)
	
	preparation.start()


func _on_battle_started() -> void:
	prep_panel.hide()
	enemy_zone_overlay.hide()


func _on_unit_captured(unit: Unit) -> void:
	if unit.stats.team == preparation.player_team:
		RunState.lose_piece(unit.stats)
	else:
		captured_enemies += 1


func _on_battle_ended(result: GameRules.Result) -> void:
	outcome = GameRules.get_outcome(result, preparation.player_team)
	var rewards := BattleRewards.calculate(outcome, captured_enemies, RunState.money)
	battle_result.show_result(outcome, rewards, captured_enemies)


func _on_battle_result_closed() -> void:
	# On a loss the result popup already reset the run: start a new one.
	if outcome == GameRules.Outcome.LOSS:
		get_tree().change_scene_to_file(PIECE_WHEELS_SCENE)
		return
	
	if RunState.advance():
		# TODO: show a victory screen.
		RunState.reset()
		get_tree().change_scene_to_file("res://scenes/main-menu/main_menu.tscn")
		return
	
	if not RunState.graveyard.is_empty():
		graveyard_panel.open()
		return
	
	# TODO: go to the shop instead once it exists.
	get_tree().reload_current_scene()
