# res://scenes/ui/cutting_board_area.gd
extends TextureRect
class_name CuttingBoardArea

# ---------------- Config (opcional: arraste presets no Inspector) ----------------
@export var cutting_difficulties: Array[CuttingDifficultyResource] = []  # Array de CuttingDifficultyResource (resources .tres)

# ---------------- Vars ----------------
var current_ingredient: Node = null   # Ingrediente cortado atualmente na tábua
var active: bool = false              # Minigame/ingrediente em andamento

# ---------------- DROP checks ----------------
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not (data.has("id") and data.has("state")):
		return false

	# só aceita ingredientes raw que suportem "cut" (via IngredientData)
	if data["state"] != "raw":
		return false

	var ingredient: IngredientData = Managers.ingredient_database.get_ingredient(data["id"])
	if ingredient == null:
		return false

	return ingredient.states.has("cut")


func _drop_data(_pos: Vector2, data: Variant) -> void:
	AudioManager.play_sfx(AudioManager.library.ingredient_drop)
	if active:
		return
	if not _can_drop_data(_pos, data):
		return

	# Instancia minigame
	var scene := preload("res://scenes/minigames/cutting_board_qte.tscn")
	var minigame: CuttingBoardQTE = scene.instantiate()
	minigame.ingredient_name = data["id"]
	minigame.board_area = self

	# escolher preset baseado no dia (se tiver presets)
	if cutting_difficulties.size() > 0:
		# tenta obter dia atual
		var day := 1
		var ms := get_tree().current_scene
		if ms and ms.has_method("get"):
			var maybe_day = ms.get("day")
			if typeof(maybe_day) == TYPE_INT:
				day = maybe_day



		# selecionar melhor preset (maior min_day <= day)
		var best = null
		for p in cutting_difficulties:
			if p is CuttingDifficultyResource:
				if p.min_day <= day:
					if best == null or p.min_day > best.min_day:
						best = p
		if best != null:
			minigame.difficulty_preset = best

	# Adiciona no parent (PrepArea) para ficar no mesmo "espaço" do scroll
	var parent_node: Node = get_parent()
	parent_node.add_child(minigame)
	minigame.position = position

	active = true

	# Esconde a faca da bancada enquanto minigame roda (mantém nó para restaurar)
	var bancada_knife: Node = $BancadaKnife
	if bancada_knife:
		bancada_knife.visible = false

# ---------------- RESULTADOS ----------------
func notify_result_placed(node: Node) -> void:
	# salva referência ao ingrediente que ficou na tábua
	current_ingredient = node

	# quando o ingrediente sair da cena (arrastado/destinado), limpar estado
	current_ingredient.tree_exited.connect(func():
		current_ingredient = null
		active = false)

func notify_ingredient_removed() -> void:
	current_ingredient = null
	active = false


#------------ API P/ QTE -----------------------

func get_cutting_difficulties() -> Array[CuttingDifficultyResource]:
	return cutting_difficulties
