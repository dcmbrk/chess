class_name Arena
extends Node2D

const CELL_SIZE := Vector2(8, 8)
const HALF_CELL_SIZE := Vector2(4, 4)
const QUARTER_CELL_SIZE := Vector2(2, 2)

@onready var unit_mover: UnitMover = $UnitMover
@onready var unit_spawner: UnitSpawner = $UnitSpawner
@onready var move_highlighter: MoveHighlighter = $MoveHighlighter
@onready var turn_manager: TurnManager = $TurnManager
@onready var board: PlayArea = $Board
@onready var battle_result: BattleResult = $BattleResult
@onready var preparation: PreparationPhase = $PreparationPhase
@onready var prep_panel: PrepPanel = $PrepPanel
@onready var enemy_zone_overlay: EnemyZoneOverlay = $Board/EnemyZoneOverlay

var captured_enemies := 0

func _ready() -> void:
	unit_spawner.unit_spawned.connect(unit_mover.setup_unit)
	unit_spawner.unit_spawned.connect(move_highlighter.setup_unit)
	unit_mover.unit_captured.connect(_on_unit_captured)
	turn_manager.battle_ended.connect(_on_battle_ended)
	battle_result.closed.connect(_on_battle_result_closed)
	preparation.pieces_changed.connect(prep_panel.update_pieces)
	preparation.battle_started.connect(_on_battle_started)
	prep_panel.go_pressed.connect(preparation.start_battle)
	
	preparation.start()


func _on_battle_started() -> void:
	prep_panel.hide()
	enemy_zone_overlay.hide()


func _on_unit_captured(unit: Unit) -> void:
	if unit.stats.team != preparation.player_team:
		captured_enemies += 1


func _on_battle_ended(result: GameRules.Result) -> void:
	var outcome := GameRules.get_outcome(result, preparation.player_team)
	var rewards := BattleRewards.calculate(outcome, captured_enemies, RunState.money)
	battle_result.show_result(outcome, rewards, captured_enemies)


func _on_battle_result_closed() -> void:
	# TODO: go to the shop instead once it exists.
	get_tree().reload_current_scene()
