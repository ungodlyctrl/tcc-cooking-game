extends TextureRect
class_name TopDeliveryArea

func _can_drop_data(_pos, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "delivered_plate"

func _drop_data(_pos, data) -> void:
	if not _can_drop_data(_pos, data):
		return

	# dentro de _drop_data, antes de main.switch_mode(...)
	var delivered_plate := preload("res://scenes/ui/delivered_plate.tscn").instantiate()
	delivered_plate.ingredients = data["ingredients"]

# tenta pegar sprite de delivered do recipe atual
	var main := get_tree().current_scene
	if main and main.current_recipe and main.current_recipe.delivered_plate_sprite:
		delivered_plate.plate_texture = main.current_recipe.delivered_plate_sprite
	else:
		delivered_plate.plate_texture = preload("res://assets/prato2.png") # fallback


	var source_node : Control = data.get("source", null)
	if source_node and source_node is Node:
		source_node.queue_free()

	main.switch_mode(main.GameMode.ATTENDANCE)
	main.call_deferred("_spawn_delivered_plate", delivered_plate)

	# 🔥 esconde a DialogueBox quando está entregando
	main.mode_attendance.dialogue_box.hide_box()
