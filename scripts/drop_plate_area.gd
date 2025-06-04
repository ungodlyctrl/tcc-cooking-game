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

	# Coleta ingredientes de ferramentas (panela/frigideira) ou direto
	var ingredients_to_add: Array[Dictionary] = []

	if data.has("type") and data["type"] == "cooked_tool":
		if data.has("ingredients"):
			ingredients_to_add = data["ingredients"]
	else:
		ingredients_to_add.append({
			"id": data["id"],
			"state": data["state"]
		})

	# Adiciona cada ingrediente à lista local e à interface
	for ingredient in ingredients_to_add:
		used_ingredients.append(ingredient)

	_update_ingredient_list_ui()

	# Remove a fonte (panela, frigideira, etc) se for necessário
	var source_node : Control = data.get("source", null)
	if source_node and source_node is Node:
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
