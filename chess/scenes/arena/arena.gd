class_name Arena
extends Node2D

const CELL_SIZE := Vector2(8, 8)
const HALF_CELL_SIZE := Vector2(4, 4)
const QUARTER_CELL_SIZE := Vector2(2, 2)
const PIECE_WHEELS_SCENE := "res://scenes/piece_wheels/piece_wheels.tscn"
const SHOP_SCENE := "res://scenes/shop/shop_screen.tscn"

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
@onready var unit_seller: UnitSeller = $UnitSeller
@onready var unit_tooltip: UnitTooltip = $UnitTooltip

var captured_enemies := 0
var outcome: GameRules.Outcome

func _ready() -> void:
	unit_spawner.unit_spawned.connect(unit_mover.setup_unit)
	unit_spawner.unit_spawned.connect(move_highlighter.setup_unit)
	unit_spawner.unit_spawned.connect(unit_seller.setup_unit)
	unit_spawner.unit_spawned.connect(unit_tooltip.setup_unit)
	unit_mover.unit_captured.connect(_on_unit_captured)
	turn_manager.battle_ended.connect(_on_battle_ended)
	battle_result.closed.connect(_on_battle_result_closed)
	preparation.pieces_changed.connect(prep_panel.update_pieces)
	preparation.battle_started.connect(_on_battle_started)
	prep_panel.go_pressed.connect(preparation.start_battle)
	graveyard_panel.closed.connect(_go_to_shop)
	
	if not encounter:
		encounter = RunState.pick_encounter()
	for tile in encounter.pieces:
		unit_spawner.spawn_unit_at(encounter.pieces[tile], board, tile)
	
	for piece in RunState.pieces:
		unit_spawner.spawn_unit(piece)
	
	preparation.max_pieces = RunState.get_board_slots()
	preparation.start()


func _on_battle_started() -> void:
	prep_panel.hide()
	enemy_zone_overlay.hide()


func _on_unit_captured(unit: Unit, by: Unit) -> void:
	if unit.stats.team == preparation.player_team:
		RunState.lose_piece(unit.get_run_stats())
	else:
		captured_enemies += 1
		RunState.add_money(RunState.get_capture_bonus(by.stats, unit.stats))


func _on_battle_ended(result: GameRules.Result) -> void:
	outcome = GameRules.get_outcome(result, preparation.player_team)
	var rewards := BattleRewards.calculate(outcome, captured_enemies, RunState.money)
	RunState.apply_gambits_to_rewards(rewards, outcome)
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
	
	_go_to_shop()


func _go_to_shop() -> void:
	get_tree().change_scene_to_file(SHOP_SCENE)
