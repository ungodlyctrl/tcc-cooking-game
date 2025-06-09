extends TextureRect
class_name TrashBin

@export var closed_texture: Texture2D
@export var open_texture: Texture2D

func _ready():
	texture = closed_texture
	mouse_filter = Control.MOUSE_FILTER_PASS  # garante que receba eventos de mouse

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("type")

func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return

	if data["type"] == "cooked_tool":
		var source : Control = data.get("source", null)
		if source and source.is_inside_tree():
			source.queue_free()

	elif data["type"] == "delivered_plate":
		var source : Control = data.get("source", null)
		if source and source is DropPlateArea:
			source.used_ingredients.clear()
			source._update_ingredient_list_ui()

	

func _on_mouse_entered():
	texture = open_texture

func _on_mouse_exited():
	texture = closed_texture
