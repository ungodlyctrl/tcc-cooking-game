extends TextureRect

@onready var used_list := $VBoxContainer/UsedList
var used_ingredients: Array = []
var current_recipe: Resource = null
var active := false  # controle do minigame ativo

func set_current_recipe(recipe: Resource):
	current_recipe = recipe
	used_ingredients.clear()

	# Limpar visualmente o painel
	for child in used_list.get_children():
		child.queue_free()

	print("📦 Receita recebida no DropArea:", recipe.name)

func _can_drop_data(position, data):
	var valid = typeof(data) == TYPE_DICTIONARY and data.has("id") and data.get("state") == "raw"
	self.modulate = Color(1, 1, 1, 1.0) if valid else Color(1, 0.5, 0.5, 0.8)
	return valid

func _drop_data(position, data):
	self.modulate = Color(1, 1, 1, 1)  # reset modulate

	if active:
		print("🟡 Já tem um minigame ativo na tábua.")
		return

	if not _can_drop_data(position, data):
		print("❌ Ingrediente inválido.")
		return

	print("🔪 Iniciando corte de:", data["id"])
	active = true

	var board := preload("res://scenes/minigames/cutting_board_qte.tscn").instantiate()
	board.ingredient_name = data["id"]

	# Converte a posição global da tábua para a cena principal
	var global = self.get_global_position()
	board.position = get_tree().current_scene.to_local(global)

	get_tree().current_scene.add_child(board)

	# Libera uso da tábua após o minigame sair da árvore
	board.tree_exited.connect(func():
		active = false
	)

	# Atualizar lista de ingredientes usados (se quiser manter isso aqui)
	used_ingredients.append(data["id"])

	var label := Label.new()
	label.text = "- " + data["id"].capitalize()
	used_list.add_child(label)
	print("✅ Ingrediente adicionado:", data["id"])
