extends TextureRect
class_name DropPlateArea

## DropPlateArea (Prato principal onde os ingredientes são montados)
## Responsável por:
## - Receber ingredientes/utensílios arrastados.
## - Manter lista de ingredientes usados.
## - Mostrar lista (texto temporário) ou sprite final (futuro).
## - Permitir arrastar o prato completo para entrega.

# -------------------------------
# NÓS DA CENA
# -------------------------------
@onready var used_list: VBoxContainer = $VBoxContainer/UsedList
# No futuro: adicionar um TextureRect aqui para sprites do prato final

# -------------------------------
# VARIÁVEIS PRINCIPAIS
# -------------------------------
var used_ingredients: Array[Dictionary] = []     ## Ingredientes usados no prato
var expected_recipe: RecipeResource              ## Receita atual recebida do MainScene


# -------------------------------
# CONFIGURAÇÃO INICIAL
# -------------------------------
func set_current_recipe(recipe: RecipeResource) -> void:
	## Define a receita e limpa o prato
	expected_recipe = recipe
	clear_ingredients()


# -------------------------------
# GESTÃO DE INGREDIENTES
# -------------------------------
func clear_ingredients() -> void:
	## Limpa todos os ingredientes do prato
	used_ingredients.clear()
	for child in used_list.get_children():
		child.queue_free()
	# Futuro: resetar sprite do prato também


func add_ingredients(ingredients: Array[Dictionary]) -> void:
	## Adiciona ingredientes e atualiza visualização
	for ing in ingredients:
		used_ingredients.append(ing)
	_update_ingredient_list_ui()
	# Futuro: atualizar sprite aqui


# -------------------------------
# DRAG & DROP
# -------------------------------
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

	# Caso 1: veio de um utensílio (panela, frigideira etc.)
	if data.has("type") and data["type"] == "cooked_tool":
		if data.has("ingredients"):
			ingredients_to_add = data["ingredients"]

	# Caso 2: ingrediente individual
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

	# Adiciona ao prato
	add_ingredients(ingredients_to_add)

	# Atualiza score
	get_tree().current_scene.update_score_display()

	# Remove origem (ingrediente ou utensílio)
	var source_node: Control = data.get("source", null)
	if source_node and source_node.is_inside_tree():
		source_node.queue_free()

	DragManager.current_drag_type = DragManager.DragType.NONE


func _get_drag_data(_position: Vector2) -> Variant:
	## Permite arrastar o prato inteiro para entregar
	if used_ingredients.is_empty():
		return null

	var preview := TextureRect.new()
	preview.texture = preload("res://assets/prato7.png")  # sprite genérico temporário
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.custom_minimum_size = Vector2(96, 96)
	set_drag_preview(preview)

	DragManager.current_drag_type = DragManager.DragType.PLATE

	return {
		"type": "delivered_plate",
		"ingredients": used_ingredients.duplicate(true),  ## cópia profunda
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
