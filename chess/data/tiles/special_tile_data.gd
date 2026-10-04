## A special floor tile the player buys in the shop and places in their rows.
class_name SpecialTileData
extends Resource

enum Effect {
	## The player's piece standing on it can't be captured.
	PROTECTION,
	## The player's piece ending a move on it earns money.
	BENEDICTION,
	## An enemy piece moving onto it is destroyed.
	HUNTER,
	## Enemy pieces can't enter or slide through it.
	PHANTOM,
}

const BENEDICTION_MONEY := 1

@export var display_name := ""
@export_multiline var description := ""
@export var effect := Effect.PROTECTION
@export var price := 4
@export var texture: Texture2D


## Adds this tile's rule to a board snapshot. [param owner] is the player's team.
func apply_to(board: BoardState, tile: Vector2i, owner: UnitStats.Team) -> void:
	match effect:
		Effect.PROTECTION:
			board.protected_tiles[tile] = owner
		Effect.HUNTER:
			board.trap_tiles[tile] = UnitStats.get_opponent(owner)
		Effect.PHANTOM:
			board.forbidden_tiles[tile] = UnitStats.get_opponent(owner)
