## The owned gambits, drawn over the arena's relic column.
class_name GambitBar
extends VBoxContainer


func _ready() -> void:
	RunState.gambits_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	for gambit in RunState.gambits:
		var icon := TextureRect.new()
		icon.texture = gambit.create_icon()
		icon.custom_minimum_size = GambitData.ICON_SIZE
		Tooltip.attach_gambit(icon, gambit)
		icon.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(icon)
