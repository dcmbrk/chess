extends Control

const PIECE_WHEELS_SCENE := "res://scenes/piece_wheels/piece_wheels.tscn"

@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var collection_button: Button = %CollectionButton
@onready var credits_button: Button = %CreditsButton
@onready var quit_button: Button = %QuitButton
@onready var credits_panel: Control = %CreditsPanel
@onready var credits_close_button: Button = %CreditsCloseButton
@onready var settings_panel: SettingsPanel = $SettingsPanel


func _ready() -> void:
	credits_panel.hide()
	play_button.pressed.connect(_on_play_pressed)
	credits_button.pressed.connect(credits_panel.show)
	credits_close_button.pressed.connect(credits_panel.hide)
	quit_button.pressed.connect(get_tree().quit)
	settings_button.pressed.connect(settings_panel.open)
	
	# TODO: enable once the collection screen exists.
	collection_button.disabled = true
	Tooltip.attach(collection_button, collection_button.text, "", "Coming soon")


func _on_play_pressed() -> void:
	RunState.reset()
	get_tree().change_scene_to_file(PIECE_WHEELS_SCENE)
