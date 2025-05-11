extends TextureRect

@onready var used_list := $VBoxContainer/UsedList
var used_ingredients: Array = []
var current_recipe: Resource = null

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
	if data in used_ingredients:
		print("⚠️ Ingrediente já adicionado:", data)
		return
	if typeof(data) == TYPE_STRING:
		# Aqui você decide se esse ingrediente precisa ser cortado
		if data in ["cenoura", "carne", "cebola"]:  # só corta os que precisam
			var board = preload("res://scenes/minigames/cutting_board.tscn").instantiate()
			board.ingredient_name = data
			add_child(board)

	used_ingredients.append(data)

	var label := Label.new()
	label.text = "- " + data.capitalize()
	used_list.add_child(label)
	print("✅ Ingrediente adicionado:", data)
