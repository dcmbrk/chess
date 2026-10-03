class_name DragAndDrop
extends Node

signal started
signal canceled(start_position: Vector2)
signal dropped(start_position: Vector2)

@export var enabled := true
@export var target: Area2D
enum STATES { IDLE, DRAGGING }
var state: STATES = STATES.IDLE
var starting_position: Vector2 = Vector2.ZERO
var offset: Vector2

func _ready() -> void:
	target.input_event.connect(_on_target_input_event.unbind(1))

func _process(delta: float) -> void:

	if state == STATES.DRAGGING:
		target.global_position = target.get_global_mouse_position() + offset

func _on_target_input_event(viewport: Node, event: InputEvent):
	if not enabled:
		return
		
	var dragging_object := get_tree().get_first_node_in_group("dragging")
	if state == STATES.IDLE and dragging_object:
		return
	
	if event.is_action_pressed("left_mouse_pressed"):
		_start_dragging()
	if event.is_action_released("left_mouse_pressed"):
		_end_dragging()

func _start_dragging() -> void:
	starting_position = target.global_position
	offset =  target.global_position - target.get_global_mouse_position()
	state = STATES.DRAGGING
	started.emit()
	target.z_index = 99
	target.add_to_group("dragging")
	
func _end_dragging() -> void:
	state = STATES.IDLE
	dropped.emit(starting_position)
	target.remove_from_group("dragging")
	target.z_index = 0
