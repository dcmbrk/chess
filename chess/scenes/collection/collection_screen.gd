## Everything the player discovered: pieces, gambits and bosses.
class_name CollectionScreen
extends Control

enum Tab { PIECES, GAMBITS, BOSSES }

const TAB_NAMES := {Tab.PIECES: "Pieces", Tab.GAMBITS: "Gambits", Tab.BOSSES: "Bosses"}
const UNKNOWN_COLOR := Color(0.35, 0.33, 0.38, 1)

@export_file("*.tscn") var back_scene := "res://scenes/main-menu/main_menu.tscn"

var current_tab := Tab.PIECES

@onready var tab_buttons: Dictionary = {
	Tab.PIECES: %PiecesTab,
	Tab.GAMBITS: %GambitsTab,
	Tab.BOSSES: %BossesTab,
}
@onready var counter_label: Label = %CounterLabel
@onready var entries: GridContainer = %Entries
@onready var stats_label: Label = %StatsLabel
@onready var back_button: Button = %BackButton


func _ready() -> void:
	for tab: Tab in tab_buttons:
		(tab_buttons[tab] as Button).pressed.connect(show_tab.bind(tab))
	back_button.pressed.connect(_on_back_pressed)
	stats_label.text = "Runs %d · Wins %d · Best stage %d" % [Progress.runs_started, Progress.runs_won, Progress.best_stage]
	show_tab(Tab.PIECES)


func show_tab(tab: Tab) -> void:
	current_tab = tab
	for other: Tab in tab_buttons:
		(tab_buttons[other] as Button).disabled = other == tab
	
	for child in entries.get_children():
		entries.remove_child(child)
		child.queue_free()
	
	var all := get_entries(tab)
	var found := 0
	for resource in all:
		var discovered := Progress.is_discovered(resource)
		if discovered:
			found += 1
		entries.add_child(_create_entry(resource, discovered))
	counter_label.text = "%s %d/%d" % [TAB_NAMES[tab], found, all.size()]


static func get_entries(tab: Tab) -> Array:
	match tab:
		Tab.PIECES:
			return RunState.SHOP_POOL
		Tab.GAMBITS:
			return RunState.GAMBIT_POOL
	return RunState.BOSS_POOL


func _create_entry(resource: Resource, discovered: bool) -> Button:
	if not discovered:
		var unknown := UiStyle.create_piece_button(null, "?", UNKNOWN_COLOR)
		unknown.custom_minimum_size = Vector2(12, 10)
		Tooltip.attach(unknown, "???", "", "Not discovered yet")
		return unknown
	
	var entry: Button
	if resource is UnitStats:
		entry = UiStyle.create_piece_button(resource, "")
	elif resource is GambitData:
		entry = UiStyle.create_piece_button(null, "")
		entry.icon = (resource as GambitData).create_icon()
		Tooltip.attach_gambit(entry, resource)
	else:
		var boss := resource as BossData
		entry = UiStyle.create_piece_button(null, boss.display_name.get_slice(" ", 0))
		Tooltip.attach(entry, boss.display_name, "Boss", boss.description, Tooltip.RARITY_COLORS[GambitData.Rarity.EPIC])
	entry.custom_minimum_size = Vector2(12, 10)
	return entry


func _on_back_pressed() -> void:
	Tooltip.hide_tooltip()
	if back_scene:
		get_tree().change_scene_to_file(back_scene)
