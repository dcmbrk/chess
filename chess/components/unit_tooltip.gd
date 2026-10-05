## Shows the hovered piece's name, and how to sell it while preparing.
class_name UnitTooltip
extends Node

@export var seller: UnitSeller


func _ready() -> void:
	var units := get_tree().get_nodes_in_group("units")
	for unit: Unit in units:
		setup_unit(unit)


func setup_unit(unit: Unit) -> void:
	unit.mouse_entered.connect(_on_unit_mouse_entered.bind(unit))
	unit.mouse_exited.connect(Tooltip.hide_tooltip.bind(unit))
	unit.drag_and_drop.drag_started.connect(Tooltip.hide_tooltip.bind(unit))


static func get_subtitle(unit: Unit, sellable: bool) -> String:
	if sellable:
		return "Hold right click: sell +$%d" % unit.get_run_stats().get_sell_price()
	return ""


## The unit's special tile statuses, one per line.
static func get_status_text(unit: Unit) -> String:
	var lines: Array[String] = []
	if unit.is_temporary:
		lines.append("Phantom copy: gone after this battle.")
	if unit.is_protected:
		lines.append("Protected: can't be captured this turn.")
	if unit.is_blessed:
		lines.append("Blessed: returns to the Stock if captured.")
	if unit.is_trapped:
		lines.append("Trapped: skips its next turn.")
	return "\n".join(lines)


func _on_unit_mouse_entered(unit: Unit) -> void:
	if get_tree().get_first_node_in_group("dragging"):
		return
	
	var rect := Rect2(unit.global_position - Arena.HALF_CELL_SIZE, Arena.CELL_SIZE)
	Tooltip.show_tooltip(unit, rect, unit.stats.get_display_name(), get_subtitle(unit, seller.can_sell(unit)), get_status_text(unit))
