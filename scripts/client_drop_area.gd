extends TextureRect
class_name ClientDropArea

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type", "") == "delivered_plate"

func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return

	var main := get_tree().current_scene
	var recipe : RecipeResource = main.current_recipe
	

	# Avaliação do prato
	var result := EvaluationManager.evaluate_plate(
		recipe,
		data["ingredients"],
		main.prep_start_minutes,
		main.current_time_minutes,
		{}
	)
	var final_score : int = result.get("score", 0)
	var comment : String = result.get("comment", "")
	
	var base_price : int = recipe.base_price
	var final_payment := base_price

	if final_score >= 90:
		final_payment = int(base_price * 1.15)  # +15%
	elif final_score >= 75:
		final_payment = base_price  # normal
	elif final_score >= 50:
		final_payment = int(base_price * 0.9)  # -10%
	else:
		final_payment = int(base_price * 0.6)  # -40%

	

	# Remove prato visual
	var plate : Node = data.get("source", null)
	if plate and plate is Node:
		plate.queue_free()

	# Agora delega para a função de finalização controlada na MainScene
	main.finalize_attendance(final_score, final_payment, comment)
