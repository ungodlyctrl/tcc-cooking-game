extends TextureRect
class_name DropPlateArea

## Prato principal (área de montagem e entrega)

@onready var used_list: VBoxContainer = $VBoxContainer/UsedList

# 🔹 Offset de preview para o prato (ajusta sprite no cursor)
const PLATE_DRAG_OFFSET := Vector2(-40, -30)

var used_ingredients: Array[Dictionary] = []
var expected_recipe: RecipeResource


func set_current_recipe(recipe: RecipeResource) -> void:
	expected_recipe = recipe
	clear_ingredients()


func clear_ingredients() -> void:
	used_ingredients.clear()
	for child in used_list.get_children():
		child.queue_free()


func add_ingredients(ingredients: Array[Dictionary]) -> void:
	for ing in ingredients:
		used_ingredients.append(ing)
	_update_ingredient_list_ui()


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.has("type") and data["type"] == "cooked_tool":
		return true
	if data.has("id") and data.has("state") and data["state"]:
		return true
	return false


func _drop_data(_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_position, data):
		return

	var ingredients_to_add: Array[Dictionary] = []

	if data.has("type") and data["type"] == "cooked_tool":
		if data.has("ingredients"):
			ingredients_to_add = data["ingredients"]
	else:
		var ingredient_data := {
			"id": data.get("id", ""),
			"state": data.get("state", "")
		}
		if data.has("result"):
			ingredient_data["result"] = data["result"]

		var source_node: Control = data.get("source", null)
		if source_node and source_node.has_meta("qte_hits"):
			ingredient_data["qte_hits"] = source_node.get_meta("qte_hits")

		ingredients_to_add.append(ingredient_data)

	add_ingredients(ingredients_to_add)
	get_tree().current_scene.update_score_display()

	var source_node: Control = data.get("source", null)
	if source_node and source_node.is_inside_tree() and source_node != self:
		source_node.queue_free()

	DragManager.current_drag_type = DragManager.DragType.NONE


func _get_drag_data(_position: Vector2) -> Variant:
	if used_ingredients.is_empty():
		return null

	var preview := TextureRect.new()
	preview.texture = preload("res://assets/prato7.png")
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var wrapper := Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(preview)
	preview.position = PLATE_DRAG_OFFSET

	set_drag_preview(wrapper)
	DragManager.current_drag_type = DragManager.DragType.PLATE

	return {
		"type": "delivered_plate",
		"ingredients": used_ingredients.duplicate(true),
		"source": self
	}



# -------------------------------
# VISUALIZAÇÃO (TEMPORÁRIA: TEXTO)
# -------------------------------
func _update_ingredient_list_ui() -> void:
	## Limpa lista textual atual
	for child in used_list.get_children():
		child.queue_free()

	## Agrupa ingredientes por ID + state
	var count_map := {}

	for ing in used_ingredients:
		var key := "%s|%s" % [ing["id"], ing["state"]]
		count_map[key] = count_map.get(key, 0) + 1

	for key in count_map.keys():
		var parts : PackedStringArray = key.split("|")
		var id: String = parts[0]
		var state: String = parts[1]
		var amount: int = count_map[key]

		var label := Label.new()
		label.text = "- %s (%s) x%d" % [id.capitalize(), state, amount]
		used_list.add_child(label)

	# Futuro: aqui também pode ser disparada atualização do sprite do prato
