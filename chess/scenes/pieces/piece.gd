class_name Piece
extends Area2D

@export var stats: PieceStats: set = set_stats
@onready var skin: Sprite2D = $Skin
@onready var drag_and_drop: DragAndDrop = $DragAndDrop

func _ready() -> void:
	drag_and_drop.drop.connect(reset)

func reset(starting_position: Vector2) -> void:
	#print(starting_position)
	#global_position = starting_position
	pass

func set_stats(value: PieceStats) -> void:
	stats = value
	
	if not is_node_ready():
		await ready
		
	skin.region_rect.position = Vector2(stats.sprite_coordinates) * Arena.TILE_SIZE
