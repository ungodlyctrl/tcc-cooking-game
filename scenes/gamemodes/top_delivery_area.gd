extends TextureRect
class_name TopDeliveryArea

func _can_drop_data(_pos, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "delivered_plate"

func _drop_data(_pos, data) -> void:
	if not _can_drop_data(_pos, data):
		return

	var main := get_tree().current_scene
	main.pending_delivery = data["ingredients"]
	
	# Cria o prato visual na próxima cena
	var delivered_plate := preload("res://scenes/ui/delivered_plate.tscn").instantiate()
	delivered_plate.ingredients = data["ingredients"]
	delivered_plate.plate_texture = preload("res://assets/prato2.png")

	# Remove prato visual
	var source_node : Control = data.get("source", null)
	if source_node and source_node is Node:
		source_node.queue_free()

	main.switch_mode(main.GameMode.ATTENDANCE)
	main.call_deferred("_spawn_delivered_plate", delivered_plate)
