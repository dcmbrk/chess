## A passive item bought in the shop. Subclasses override the hooks they need.
class_name GambitData
extends Resource

enum Rarity { COMMON, RARE, EPIC }

const ICON_TEXTURE := preload("res://assets/sprites/SpriteSheet.png")
const ICON_SIZE := Vector2(8, 8)
## Shop weight of each rarity.
const RARITY_WEIGHTS := {Rarity.COMMON: 6, Rarity.RARE: 3, Rarity.EPIC: 1}

@export var display_name := ""
@export_multiline var description := ""
@export var rarity := Rarity.COMMON
@export var price := 5
## Cell in SpriteSheet.png.
@export var icon_coordinates: Vector2i


func create_icon() -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = ICON_TEXTURE
	icon.region = Rect2(Vector2(icon_coordinates) * ICON_SIZE, ICON_SIZE)
	return icon


## Money the player gets right away when [param capturer] takes [param captured].
func get_capture_bonus(_capturer: UnitStats, _captured: UnitStats) -> int:
	return 0


func modify_rewards(_rewards: BattleRewards, _outcome: GameRules.Outcome, _money: int) -> void:
	pass


## Extra pieces the player may place on the board.
func get_board_slot_bonus() -> int:
	return 0
