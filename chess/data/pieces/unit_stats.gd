class_name UnitStats
extends Resource

const TEXTURE := preload("res://assets/sprites/piece.png")
## Size of one piece in TEXTURE.
const SPRITE_SIZE := Vector2(8, 8)

enum Type { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }
enum Team { WHITE, BLACK }

@export var type: Type
@export var team: Team
@export var skin_coordinates: Vector2i
## Buying price in the shop.
@export var price := 1
## What this piece turns into when it reaches the last row (pawns).
@export var promotes_to: UnitStats


static func get_opponent(of_team: Team) -> Team:
	return Team.BLACK if of_team == Team.WHITE else Team.WHITE


## The piece's sprite as a texture, for UI.
func create_icon() -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = TEXTURE
	icon.region = Rect2(Vector2(skin_coordinates) * SPRITE_SIZE, SPRITE_SIZE)
	return icon


## Half of the buying price, rounded up.
func get_sell_price() -> int:
	return ceili(price / 2.0)


func get_display_name() -> String:
	return Type.keys()[type].capitalize()
