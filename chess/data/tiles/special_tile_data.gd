## A special floor tile the player buys in the shop and places in their rows.
class_name SpecialTileData
extends Resource

## Like the original game, effects trigger when a piece moves onto the tile.
## TileEffects applies them.
enum Effect {
	## Protective: your piece can't be captured during the enemy's next turn.
	PROTECTION,
	## Blessed: your piece is blessed; if it gets captured, it returns to the Stock.
	BENEDICTION,
	## Trap: an enemy piece is trapped and skips its next turn.
	HUNTER,
	## Phantom: your piece leaves a phantom copy in the Stock for this battle.
	PHANTOM,
}

@export var display_name := ""
@export_multiline var description := ""
@export var effect := Effect.PROTECTION
@export var price := 4
@export var texture: Texture2D

