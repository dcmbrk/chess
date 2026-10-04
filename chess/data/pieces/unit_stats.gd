class_name UnitStats
extends Resource

enum Type { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }
enum Team { WHITE, BLACK }

const TEXTURE := preload("res://assets/sprites/pieces/SPR_ChessPieces.png")
## TEXTURE has one row per team (white, black) and one column per type, in this order.
const SHEET_COLUMNS: Array[Type] = [Type.PAWN, Type.ROOK, Type.KNIGHT, Type.BISHOP, Type.QUEEN, Type.KING]
const SHEET_CELL := Vector2(40, 32)
## Each piece is centered in its cell; this square crop around it is what gets drawn.
const SPRITE_SIZE := Vector2(32, 32)
const SPRITE_INSET := Vector2(5, 0)

const DESCRIPTIONS := {
	Type.PAWN: "Moves 1 forward, captures diagonally. Becomes a Queen on the last row.",
	Type.KNIGHT: "Jumps in an L shape.",
	Type.BISHOP: "Slides diagonally.",
	Type.ROOK: "Slides straight.",
	Type.QUEEN: "Slides in any direction.",
	Type.KING: "Moves 1 in any direction. Losing it loses the battle.",
}

@export var type: Type
@export var team: Team
## Buying price in the shop.
@export var price := 1
## What this piece turns into when it reaches the last row (pawns).
## Used by the enemy and by the AI's search.
@export var promotes_to: UnitStats
## What the player may choose from when this piece is promoted (UnitStats).
## Typed as Resource: an Array[UnitStats] inside UnitStats makes the script reference itself and leak.
@export var promotion_options: Array[Resource] = []


static func get_opponent(of_team: Team) -> Team:
	return Team.BLACK if of_team == Team.WHITE else Team.WHITE


## The piece's sprite as a texture, for UI.
## Where this piece is drawn in TEXTURE.
func get_sprite_region() -> Rect2:
	var cell := Vector2(SHEET_COLUMNS.find(type), team) * SHEET_CELL
	return Rect2(cell + SPRITE_INSET, SPRITE_SIZE)


func create_icon() -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = TEXTURE
	icon.region = get_sprite_region()
	return icon


## Half of the buying price, rounded up.
func get_sell_price() -> int:
	return ceili(price / 2.0)


func get_display_name() -> String:
	return Type.keys()[type].capitalize()


func get_description() -> String:
	return DESCRIPTIONS[type]
