## Full screen effects (autoload "ScreenEffects"): CRT overlay and screen shake.
extends CanvasLayer

## Shake offsets in game pixels.
const SHAKE_STEPS := [Vector2(1, 0), Vector2(-1, 1), Vector2(0, -1), Vector2(1, 1)]
const SHAKE_STEP_TIME := 0.03

var _shake_tween: Tween

@onready var crt: ColorRect = %Crt


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.changed.connect(_apply_settings)
	_apply_settings()


## Shakes the game world (layer 0); UI layers stay still.
func shake() -> void:
	if not Settings.animations:
		return
	
	if _shake_tween:
		_shake_tween.kill()
	var viewport := get_viewport()
	_shake_tween = create_tween()
	for offset: Vector2 in SHAKE_STEPS:
		_shake_tween.tween_callback(viewport.set_canvas_transform.bind(Transform2D(0, offset)))
		_shake_tween.tween_interval(SHAKE_STEP_TIME)
	_shake_tween.tween_callback(viewport.set_canvas_transform.bind(Transform2D.IDENTITY))


func _apply_settings() -> void:
	crt.visible = Settings.crt
