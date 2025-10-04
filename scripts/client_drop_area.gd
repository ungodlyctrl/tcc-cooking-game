extends TextureRect
class_name ClientDropArea

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type", "") == "delivered_plate"

func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return

	var main := get_tree().current_scene as MainScene
	var recipe: RecipeResource = main.current_recipe

	# Avalia usando o Manager (com tempo REAL para penalidades)
	var result := EvaluationManager.evaluate_plate(
		recipe,
		data["ingredients"],
		main.prep_start_minutes,
		main.absolute_minutes,   ## 🔥 tempo real, não o travado
		{}
	)

	var final_score: int = result["score"]
	var comment: String = result["comment"]
	var final_payment: int = result["payment"]
	var grade: String = result["grade"]

	# Remove prato visual
	var plate: Node = data.get("source", null)
	if plate and plate.is_inside_tree():
		plate.queue_free()

	# Agora delega finalização
	main.finalize_attendance(final_score, final_payment, comment, grade)
