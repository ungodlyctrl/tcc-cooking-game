extends TextureRect

@onready var used_list := $VBoxContainer/UsedList
var used_ingredients: Array = []
var current_recipe: Resource = null
var active := false  # pra evitar múltiplos minigames



# Chamada quando começa uma nova receita
func set_current_recipe(recipe: Resource):
	current_recipe = recipe
	used_ingredients.clear()

	# Limpar visualmente o painel
	for child in used_list.get_children():
		child.queue_free()

	print("📦 Receita recebida no DropArea:", recipe.name)

# Recebe o drop de ingrediente via drag & drop padrão
func _can_drop_data(position, data):
	return typeof(data) == TYPE_STRING

func _drop_data(position, data):
	if data in ["cenoura", "carne", "batata"]:  # ingredientes que exigem corte
		var board = preload("res://scenes/minigames/cutting_board_qte.tscn").instantiate()
		board.ingredient_name = data

		# Adiciona na cena principal — supondo que esteja numa camada visível
		get_tree().current_scene.add_child(board)

		# Coloca a tábua exatamente sobre essa DropArea
		var global = self.get_global_position()
		board.position = get_tree().current_scene.to_local(global)

	used_ingredients.append(data)

	var label := Label.new()
	label.text = "- " + data.capitalize()
	used_list.add_child(label)
	print("✅ Ingrediente adicionado:", data)
