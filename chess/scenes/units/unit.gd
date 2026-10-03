class_name Unit
extends Area2D

@export var stats: PieceStats: set = set_stats
@onready var skin: Sprite2D = %Skin
@onready var drag_and_drop: DragAndDrop = $DragAndDrop
@onready var velocity_based_rotation: VelocityBasedRotation = $VelocityBasedRotation
@onready var outline_highlighter: OutlineHighlighter = $OutlineHighlighter

func _ready() -> void:
	drag_and_drop.started.connect(_on_drag_started)
	drag_and_drop.canceled.connect(_on_drag_canceled)
	drag_and_drop.dropped.connect(_on_drag_dropped)

func _on_drag_started() -> void:
	velocity_based_rotation.enabled = true
	#outline_highlighter.clear_highlight()
	
func _on_drag_canceled(start_position: Vector2) -> void:
	reset_after_dragging(start_position)
	
func _on_drag_dropped(start_position: Vector2) -> void:
	reset_after_dragging(start_position)

func reset_after_dragging(start_position: Vector2) -> void:
	velocity_based_rotation.enabled = false
	global_position = start_position

func set_stats(value: PieceStats) -> void:
	stats = value
	
	if not is_node_ready():
		await ready
		
	skin.region_rect.position = Vector2(stats.sprite_coordinates) * Arena.TILE_SIZE


func _on_mouse_entered() -> void:
	if drag_and_drop.state == drag_and_drop.STATES.DRAGGING:
		return
	
	outline_highlighter.highlight()
	z_index = 1


func _on_mouse_exited() -> void:
	if drag_and_drop.state == drag_and_drop.STATES.DRAGGING:
		return
	
	outline_highlighter.clear_highlight()
	z_index = 0
