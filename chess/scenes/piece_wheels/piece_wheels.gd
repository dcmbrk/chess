## Start of a run: three slot-machine reels pick the player's first pieces.
class_name PieceWheels
extends Control

signal finished

const REEL_COUNT := 3

@export var pool: Array[UnitStats] = []
## Same order as [member pool]; a bigger weight makes a piece more common.
@export var weights: Array[int] = []
## Seconds between two icons while a reel spins.
@export var spin_interval := 0.15
@export var stop_delay := 0.3
@export_file("*.tscn") var next_scene := "res://scenes/arena/arena.tscn"

var results: Array[UnitStats] = []
var stopped_count := 0

var _spin_time := 0.0
var _spin_index := 0

@onready var reels: Array[TextureRect] = [%Reel1, %Reel2, %Reel3]
@onready var action_button: Button = %ActionButton


func _ready() -> void:
	for i in REEL_COUNT:
		results.append(WeightedRandom.pick(pool, weights, RunState.rng))
	
	action_button.pressed.connect(_on_action_button_pressed)
	_show_spinning_icons()


func _process(delta: float) -> void:
	_spin_time += delta
	if _spin_time < spin_interval:
		return
	
	_spin_time = 0.0
	_spin_index += 1
	_show_spinning_icons()


func is_done() -> bool:
	return stopped_count == REEL_COUNT


## Stops all reels one after another, left to right.
func stop() -> void:
	action_button.disabled = true
	
	while not is_done():
		_stop_next_reel()
		if not is_done() and stop_delay > 0.0:
			await get_tree().create_timer(stop_delay).timeout
	
	action_button.text = "Start!"
	action_button.disabled = false


func _stop_next_reel() -> void:
	reels[stopped_count].texture = results[stopped_count].create_icon()
	stopped_count += 1


func _show_spinning_icons() -> void:
	for i in range(stopped_count, REEL_COUNT):
		reels[i].texture = pool[(_spin_index + i) % pool.size()].create_icon()


func _on_action_button_pressed() -> void:
	if not is_done():
		stop()
		return
	
	RunState.pieces = results.duplicate()
	finished.emit()
	if next_scene:
		get_tree().change_scene_to_file(next_scene)
