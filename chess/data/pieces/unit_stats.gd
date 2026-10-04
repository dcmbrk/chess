class_name UnitStats
extends Resource

enum Type { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }
enum Team { WHITE, BLACK }

@export var type: Type
@export var team: Team
@export var skin_coordinates: Vector2i
