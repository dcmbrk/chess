## Player preferences (autoload "Settings"), saved between sessions.
extends Node

signal changed

const DEFAULT_PATH := "user://settings.cfg"
const VOLUME_STEP := 10
## How much faster the enemy plays with fast_enemy on.
const FAST_ENEMY_FACTOR := 0.4

## Tests point this at a throwaway file.
var path := DEFAULT_PATH

## 0 to 100, in steps of VOLUME_STEP.
var volume := 80
var fullscreen := false
var move_hints := true
var fast_enemy := false


func _ready() -> void:
	load_settings()
	apply()


func set_volume(value: int) -> void:
	volume = clampi(snappedi(value, VOLUME_STEP), 0, 100)
	_on_changed()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_on_changed()


func set_move_hints(value: bool) -> void:
	move_hints = value
	_on_changed()


func set_fast_enemy(value: bool) -> void:
	fast_enemy = value
	_on_changed()


func get_enemy_delay(base_delay: float) -> float:
	return base_delay * FAST_ENEMY_FACTOR if fast_enemy else base_delay


func reset_to_defaults() -> void:
	volume = 80
	fullscreen = false
	move_hints = true
	fast_enemy = false
	_on_changed()


func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(volume / 100.0))
	AudioServer.set_bus_mute(0, volume == 0)
	
	# The headless server (tests, CI) has no window to change.
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(mode)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	
	volume = clampi(config.get_value("audio", "volume", volume), 0, 100)
	fullscreen = config.get_value("video", "fullscreen", fullscreen)
	move_hints = config.get_value("gameplay", "move_hints", move_hints)
	fast_enemy = config.get_value("gameplay", "fast_enemy", fast_enemy)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("gameplay", "move_hints", move_hints)
	config.set_value("gameplay", "fast_enemy", fast_enemy)
	config.save(path)


func _on_changed() -> void:
	apply()
	save_settings()
	changed.emit()
