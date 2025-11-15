extends TextureRect
class_name TrashBin

const TYPE_COOKED_TOOL := "cooked_tool"
const TYPE_PLATE := "plate"

@export var closed_texture: Texture2D
@export var open_texture: Texture2D

func _ready() -> void:
	texture = closed_texture
	mouse_filter = Control.MOUSE_FILTER_PASS

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("type")

func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return

	var data_type: String = data["type"]

	if data_type == TYPE_COOKED_TOOL:
		var source: Control = data.get("source", null)
		if source and source.is_inside_tree():
			source.queue_free()

	elif data_type == TYPE_PLATE:
		var source: Control = data.get("source", null)
		if source and source is DropPlateArea:
			source.clear_ingredients()
	
	elif data_type == "ingredient":
		var source: Control = data.get("source", null)
		if source and source.is_inside_tree():
			source.queue_free()


func _on_mouse_entered() -> void:
	texture = open_texture

func _on_mouse_exited() -> void:
	texture = closed_texture
