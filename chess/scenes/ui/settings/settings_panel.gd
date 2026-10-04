## Popup editing the Settings autoload. Works while the game is paused.
class_name SettingsPanel
extends CanvasLayer

signal closed

@onready var volume_down_button: Button = %VolumeDownButton
@onready var volume_label: Label = %VolumeLabel
@onready var volume_up_button: Button = %VolumeUpButton
@onready var fullscreen_button: Button = %FullscreenButton
@onready var move_hints_button: Button = %MoveHintsButton
@onready var fast_enemy_button: Button = %FastEnemyButton
@onready var animations_button: Button = %AnimationsButton
@onready var crt_button: Button = %CrtButton
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	volume_down_button.pressed.connect(func() -> void: Settings.set_volume(Settings.volume - Settings.VOLUME_STEP))
	volume_up_button.pressed.connect(func() -> void: Settings.set_volume(Settings.volume + Settings.VOLUME_STEP))
	fullscreen_button.pressed.connect(func() -> void: Settings.set_fullscreen(not Settings.fullscreen))
	move_hints_button.pressed.connect(func() -> void: Settings.set_move_hints(not Settings.move_hints))
	fast_enemy_button.pressed.connect(func() -> void: Settings.set_fast_enemy(not Settings.fast_enemy))
	animations_button.pressed.connect(func() -> void: Settings.set_animations(not Settings.animations))
	crt_button.pressed.connect(func() -> void: Settings.set_crt(not Settings.crt))
	close_button.pressed.connect(close)
	Settings.changed.connect(_refresh)


func open() -> void:
	_refresh()
	show()


func close() -> void:
	hide()
	closed.emit()


func _refresh() -> void:
	volume_label.text = "%d%%" % Settings.volume
	volume_down_button.disabled = Settings.volume <= 0
	volume_up_button.disabled = Settings.volume >= 100
	fullscreen_button.text = _on_off(Settings.fullscreen)
	move_hints_button.text = _on_off(Settings.move_hints)
	fast_enemy_button.text = _on_off(Settings.fast_enemy)
	animations_button.text = _on_off(Settings.animations)
	crt_button.text = _on_off(Settings.crt)


static func _on_off(value: bool) -> String:
	return "On" if value else "Off"
