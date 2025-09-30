extends TextureRect
class_name CuttingBoardArea

## Área da tábua de corte na bancada.
## Aceita ingredientes crus que tenham estado "cut".
## Ao receber ingrediente válido, instancia o CuttingBoardQTE.


# ---------------- Vars ----------------
var current_ingredient: Node = null   ## Ingrediente cortado atualmente na tábua
var active: bool = false              ## Marca se já há um minigame ou ingrediente em andamento


# ---------------- Core Logic ----------------
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	## Verifica se pode aceitar o dado arrastado
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not (data.has("id") and data.has("state")):
		return false
	if data["state"] != "raw":
		return false

	var ingredient: IngredientData = IngredientDatabase.get_ingredient(data["id"])
	return ingredient != null and ingredient.states.has("cut")


func _drop_data(_pos: Vector2, data: Variant) -> void:
	## Recebe o drop de ingrediente e inicia o minigame de corte
	if active:
		return
	if not _can_drop_data(_pos, data):
		return

	# Instancia minigame
	var minigame: CuttingBoardQTE = preload("res://scenes/minigames/cutting_board_qte.tscn").instantiate()
	minigame.ingredient_name = data["id"]
	minigame.board_area = self

	# Adiciona no mesmo parent (PrepArea), assim funciona com scroll
	var parent_node: Node = get_parent()
	parent_node.add_child(minigame)

	# Posiciona na mesma posição da tábua
	minigame.position = position

	active = true

	# Esconde faca da bancada enquanto minigame roda
	var bancada_knife: Node = $BancadaKnife
	if bancada_knife:
		bancada_knife.visible = false


func notify_result_placed(node: Node) -> void:
	## Notificado pelo minigame quando ingrediente cortado é criado
	current_ingredient = node

	# Quando ingrediente sair da cena (drag/delete), libera a tábua
	current_ingredient.tree_exited.connect(func():
		current_ingredient = null
		active = false
	)


func notify_ingredient_removed() -> void:
	## Chamado caso ingrediente seja removido manualmente
	current_ingredient = null
	active = false
