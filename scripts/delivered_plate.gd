extends Control
class_name DeliveredPlate

@export var plate_texture: Texture2D
@export var ingredients: Array[Dictionary] = []

@onready var sprite: TextureRect = $PlateSprite

func _ready() -> void:
	sprite.texture = plate_texture
	set_process_unhandled_input(true)

func _get_drag_data(_pos: Vector2) -> Variant:
	var preview := self.duplicate()
	preview.modulate.a = 0.6
	set_drag_preview(preview)

	DragManager.current_drag_type = DragManager.DragType.PLATE

	return {
		"type": "delivered_plate",
		"ingredients": ingredients,
		"source": self
	}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		await get_tree().process_frame
		if not get_viewport_rect().has_point(get_global_mouse_position()):
			# Volta para posição original se não for aceito
			position = Vector2(position.x, position.y)
