@tool
class_name Unit
extends Area2D

@export var stats: UnitStats : set = set_stats
## The stats before a promotion; promotions only last for one battle.
var promoted_from: UnitStats

## Battle statuses from special tiles. Each one tints the unit.
var is_protected := false:
	set(value):
		is_protected = value
		_update_status_tint()
var is_blessed := false:
	set(value):
		is_blessed = value
		_update_status_tint()
var is_trapped := false:
	set(value):
		is_trapped = value
		_update_status_tint()
## The trapped unit already skipped its turn.
var trap_served := false
## A phantom copy: only lives for this battle, sells for nothing.
var is_temporary := false:
	set(value):
		is_temporary = value
		_update_status_tint()

const PROTECTED_TINT := Color(0.7, 0.85, 1.0)
const BLESSED_TINT := Color(1.0, 0.95, 0.6)
const TRAPPED_TINT := Color(0.6, 0.9, 0.6)
const TEMPORARY_TINT := Color(0.8, 0.85, 1.0, 0.6)

const SLIDE_TIME := 0.12

@onready var visuals: CanvasGroup = $Visuals
@onready var skin: Sprite2D = $Visuals/Skin
@onready var drag_and_drop: DragAndDrop = $DragAndDrop
@onready var velocity_based_rotation: VelocityBasedRotation = $VelocityBasedRotation
@onready var outline_highlighter: OutlineHighlighter = $OutlineHighlighter


func _ready() -> void:
	if not Engine.is_editor_hint():
		drag_and_drop.drag_started.connect(_on_drag_started)
		drag_and_drop.drag_canceled.connect(_on_drag_canceled)


func set_stats(value: UnitStats) -> void:
	stats = value
	
	if value == null:
		return
	
	if not is_node_ready():
		await ready
	
	skin.region_rect = stats.get_sprite_region()


func promote(new_stats: UnitStats) -> void:
	if not promoted_from:
		promoted_from = stats
	stats = new_stats


## The piece as it is stored in the run (ignores promotions).
func get_run_stats() -> UnitStats:
	return promoted_from if promoted_from else stats


## Moves the unit at once, but lets its sprite slide over from [param from_global].
func slide_from(from_global: Vector2) -> void:
	if not Settings.animations or not is_inside_tree():
		return
	
	visuals.position = from_global - global_position
	var tween := create_tween()
	tween.tween_property(visuals, "position", Vector2.ZERO, SLIDE_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func reset_after_dragging(starting_position: Vector2) -> void:
	velocity_based_rotation.enabled = false
	global_position = starting_position


func _on_drag_started() -> void:
	velocity_based_rotation.enabled = true


func _on_drag_canceled(starting_position: Vector2) -> void:
	reset_after_dragging(starting_position)


func _on_mouse_entered() -> void:
	if drag_and_drop.dragging:
		return
	
	outline_highlighter.highlight()
	z_index = 1


func _on_mouse_exited() -> void:
	if drag_and_drop.dragging:
		return
	
	outline_highlighter.clear_highlight()
	z_index = 0


func _update_status_tint() -> void:
	if not is_node_ready():
		return
	var tint := Color.WHITE
	if is_temporary:
		tint *= TEMPORARY_TINT
	if is_blessed:
		tint *= BLESSED_TINT
	if is_protected:
		tint *= PROTECTED_TINT
	if is_trapped:
		tint *= TRAPPED_TINT
	skin.self_modulate = tint
