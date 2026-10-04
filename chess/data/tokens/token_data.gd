## A shop token: buying it rolls a few random rewards and the player keeps one,
## like the Chess / Tile / Gambit tokens of the original game.
class_name TokenData
extends Resource

enum Kind { CHESS, TILE, GAMBIT }

const TEXTURE := preload("res://assets/sprites/shop/SPR_Gachapon_Tokens.png")

@export var display_name := ""
@export_multiline var description := ""
@export var kind := Kind.CHESS
## How many random rewards are offered; the player keeps one.
@export_range(1, 3) var choices := 1
@export var price := 5
## Where the token is drawn in TEXTURE.
@export var icon_region := Rect2(0, 0, 21, 21)


func create_icon() -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = TEXTURE
	icon.region = icon_region
	return icon
