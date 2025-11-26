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
	return typeof(data) == TYPE_DICTIONARY and data.has("type") or (data.has("state") and data["state"] == "tool")


func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return

	var data_type: String = data.get("type", "")
	var state_type: String = data.get("state", "")
	
	# se for prato → avisar DropPlateArea
	if data_type == "plate":
		var source = data.get("source", null)
		if source and source is DropPlateArea:
			source.dropped_in_trash = true

	# --- EXISTENTES ---
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

	# --- NOVO: permitir jogar fora panela normal do fogão ---
	elif data_type == "tool":
		var source = data.get("source", null)
		if source and source is BurnerSlot:
			source.remove_tool_from_burner()

	AudioManager.play_sfx(AudioManager.library.ingredient_trash)

func _on_mouse_entered() -> void:
	texture = open_texture

func _on_mouse_exited() -> void:
	texture = closed_texture
