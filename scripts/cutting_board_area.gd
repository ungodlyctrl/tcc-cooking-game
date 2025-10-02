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
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not (data.has("id") and data.has("state")):
		return false
	
	# só aceita ingredientes crus
	if data["state"] != "raw":
		return false
	
	# usa IngredientDatabase via Managers
	var ingredient: IngredientData = Managers.ingredient_database.get_ingredient(data["id"])
	if ingredient == null:
		return false
	
	# ingrediente só é válido se tiver estado "cut"
	return ingredient.states.has("cut")


func _drop_data(_pos: Vector2, data: Variant) -> void:
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
	current_ingredient = node

	current_ingredient.tree_exited.connect(func():
		current_ingredient = null
		active = false
	)


func notify_ingredient_removed() -> void:
	current_ingredient = null
	active = false
