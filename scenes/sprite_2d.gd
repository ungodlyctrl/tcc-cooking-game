extends Sprite2D

@export var follow_speed: float = 6.0
@export var scale_pressed: Vector2 = Vector2(0.035, 0.035)
@export var scale_default: Vector2 = Vector2(0.04, 0.04)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(delta: float) -> void:
	global_position = global_position.lerp(get_global_mouse_position(), follow_speed * delta)

	var is_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	var desired_scale := scale_pressed if is_pressed else scale_default
	scale = scale.lerp(desired_scale, follow_speed * delta)
