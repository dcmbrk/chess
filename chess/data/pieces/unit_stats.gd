class_name UnitStats
extends Resource

const TEXTURE := preload("res://assets/sprites/piece.png")

enum Type { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }
enum Team { WHITE, BLACK }

@export var type: Type
@export var team: Team
@export var skin_coordinates: Vector2i


static func get_opponent(of_team: Team) -> Team:
	return Team.BLACK if of_team == Team.WHITE else Team.WHITE


## The piece's sprite as a texture, for UI.
func create_icon() -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = TEXTURE
	icon.region = Rect2(Vector2(skin_coordinates) * Arena.CELL_SIZE, Arena.CELL_SIZE)
	return icon
