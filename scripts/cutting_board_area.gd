extends TextureRect
class_name CuttingBoardArea

# Armazena o ingrediente cortado atual
var current_ingredient: Node = null
var active: bool = false


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	# Só aceita ingredientes "raw" que tenham uma versão "cut"
	return typeof(data) == TYPE_DICTIONARY \
		and data.has("id") and data.has("state") \
		and data["state"] == "raw" \
		and IngredientDatabase.has_state(data["id"], "cut")


func _drop_data(_pos: Vector2, data: Variant) -> void:
	if active:
		return

	if not _can_drop_data(_pos, data):
		return

	var minigame := preload("res://scenes/minigames/cutting_board_qte.tscn").instantiate()
	minigame.ingredient_name = data["id"]
	minigame.board_area = self

	# Adiciona dentro do mesmo parent (PrepArea), para scroll funcionar
	var parent_node := get_parent()
	parent_node.add_child(minigame)

	# Posiciona na mesma posição da tábua, convertendo para local do parent
	minigame.position = self.position

	active = true


func notify_result_placed(node: Node) -> void:
	# Armazena referência ao ingrediente cortado
	current_ingredient = node

	# Quando o ingrediente for removido (por drag ou delete), liberar a tábua
	current_ingredient.tree_exited.connect(func():
		current_ingredient = null
		active = false
	)
	
func notify_ingredient_removed() -> void:
	current_ingredient = null
	active = false
