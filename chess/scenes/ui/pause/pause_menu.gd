## Pause menu and run restart (autoload "PauseMenu"). Only active in scenes of
## the "run_scenes" group (piece wheels, arena, shop).
extends CanvasLayer

const MAIN_MENU_SCENE := "res://scenes/main-menu/main_menu.tscn"
const RUN_START_SCENE := "res://scenes/piece_wheels/piece_wheels.tscn"

## Seconds R must be held to restart the run.
@export var restart_hold_time := 1.0

var restart_held_time := 0.0
## Tests clear these to stay on their own scene.
var main_menu_scene := MAIN_MENU_SCENE
var run_start_scene := RUN_START_SCENE

@onready var pause_button: Button = %PauseButton
@onready var panel: Control = %Panel
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var settings_panel: SettingsPanel = $SettingsPanel
@onready var seed_label: Label = %SeedLabel
@onready var copy_button: Button = %CopyButton
@onready var restart_label: Label = %RestartLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	restart_label.hide()
	pause_button.pressed.connect(open)
	resume_button.pressed.connect(close)
	settings_button.pressed.connect(settings_panel.open)
	main_menu_button.pressed.connect(go_to_main_menu)
	copy_button.pressed.connect(copy_seed)


func _process(delta: float) -> void:
	pause_button.visible = is_active() and not is_open()
	
	if is_active() and Input.is_action_pressed("restart_run"):
		hold_restart(delta)
	elif restart_held_time > 0.0:
		cancel_restart()


func _unhandled_input(event: InputEvent) -> void:
	if is_active() and event.is_action_pressed("pause"):
		if is_open():
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


## True while a run scene is shown.
func is_active() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.is_in_group("run_scenes")


func is_open() -> bool:
	return panel.visible


func open() -> void:
	seed_label.text = "Seed %d" % RunState.run_seed
	panel.show()
	get_tree().paused = true


func close() -> void:
	settings_panel.hide()
	panel.hide()
	get_tree().paused = false


func copy_seed() -> void:
	DisplayServer.clipboard_set(str(RunState.run_seed))


func go_to_main_menu() -> void:
	close()
	if main_menu_scene:
		get_tree().change_scene_to_file(main_menu_scene)


func hold_restart(delta: float) -> void:
	restart_held_time += delta
	restart_label.show()
	restart_label.text = "Restarting" + ".".repeat(int(restart_held_time / restart_hold_time * 3) + 1)
	if restart_held_time >= restart_hold_time:
		restart_run()


func cancel_restart() -> void:
	restart_held_time = 0.0
	restart_label.hide()


## Starts a new run with a new seed.
func restart_run() -> void:
	cancel_restart()
	close()
	Tooltip.hide_tooltip()
	RunState.reset()
	if run_start_scene:
		get_tree().change_scene_to_file(run_start_scene)
