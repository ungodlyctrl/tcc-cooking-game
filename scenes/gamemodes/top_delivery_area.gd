extends TextureRect
class_name TopDeliveryArea

func _can_drop_data(_pos, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "delivered_plate"

func _drop_data(_pos, data) -> void:
	if not _can_drop_data(_pos, data):
		return

	var main := get_tree().current_scene
	main.pending_delivery = data["ingredients"]

	# Remove prato visual
	var source_node : Control = data.get("source", null)
	if source_node and source_node is Node:
		source_node.queue_free()

	main.switch_mode(main.GameMode.ATTENDANCE)
