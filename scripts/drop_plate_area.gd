extends TextureRect
class_name DropPlateArea

## Container de texto para ingredientes usados (exibição temporária)
@onready var used_list: VBoxContainer = $VBoxContainer/UsedList

## Ingredientes usados no prato final
var used_ingredients: Array[Dictionary] = []

## Receita atual (recebida do MainScene)
var expected_recipe: RecipeResource


func set_current_recipe(recipe: RecipeResource) -> void:
	expected_recipe = recipe
	used_ingredients.clear()

	for child in used_list.get_children():
		child.queue_free()


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
		# Coleta dados extras se existirem
		var ingredient_data := {
			"id": data.get("id", ""),
			"state": data.get("state", "")
		}

		if data.has("result"):
			ingredient_data["result"] = data["result"]

		# Se o ingrediente veio de um nó com metadados (ex: cortado)
		var source_node: Control = data.get("source", null)
		if source_node and source_node.has_meta("qte_hits"):
			ingredient_data["qte_hits"] = source_node.get_meta("qte_hits")

		ingredients_to_add.append(ingredient_data)

	# Adiciona à lista principal
	for ing in ingredients_to_add:
		used_ingredients.append(ing)

	_update_ingredient_list_ui()
	
	get_tree().current_scene.update_score_display()

	# Remove a origem, como panela ou ingrediente
	var source_node: Control = data.get("source", null)
	if source_node and source_node.is_inside_tree():
		source_node.queue_free()

	DragManager.current_drag_type = DragManager.DragType.NONE


func _update_ingredient_list_ui() -> void:
	# Limpa a visualização atual
	for child in used_list.get_children():
		child.queue_free()

	# Agrupa ingredientes por ID + state
	var count_map := {}

	for ing in used_ingredients:
		var key := "%s|%s" % [ing["id"], ing["state"]]
		if not count_map.has(key):
			count_map[key] = 1
		else:
			count_map[key] += 1

	for key in count_map.keys():
		var parts = key.split("|")
		var id = parts[0]
		var state = parts[1]
		var amount = count_map[key]

		var label := Label.new()
		label.text = "- %s (%s) x%d" % [id.capitalize(), state, amount]
		used_list.add_child(label)


func _get_drag_data(_position: Vector2) -> Variant:
	if used_ingredients.is_empty():
		return null

	var preview := TextureRect.new()
	preview.texture = preload("res://assets/prato7.png")
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.custom_minimum_size = Vector2(96, 96)
	set_drag_preview(preview)

	DragManager.current_drag_type = DragManager.DragType.PLATE  # ou um novo tipo, se quiser mais controle

	return {
		"type": "delivered_plate",
		"ingredients": used_ingredients.duplicate(true),  # copia profunda
		"source": self
	}
