extends Control
class_name RecipeNotePanel

@onready var title_label = $NoteBackground/ScrollContainer/ContentBox/recipe_title
@onready var ingredient_label = $NoteBackground/ScrollContainer/ContentBox/ingredient_list
@onready var steps_label = $NoteBackground/ScrollContainer/ContentBox/preparation_steps
@onready var close_button = $NoteBackground/close_button

func _ready():
	close_button.pressed.connect(hide)
	hide()

func show_recipe(recipe: RecipeResource):
	visible = true
	title_label.text = "%s" % recipe.recipe_name

	var ing_text := ""
	for req in recipe.ingredient_requirements:
		var line = "- %s x%d" % [req.ingredient_id.capitalize(), req.quantity]
		ing_text += line + "\n"

	ingredient_label.text = "Ingredientes:\n" + ing_text.strip_edges()

	# Aqui você vai gerar os passos da receita (explico isso já já)
	steps_label.text = _generate_steps(recipe)

func _generate_steps(recipe: RecipeResource) -> String:
	var steps := ""

	# EXEMPLO SIMPLIFICADO — depois você pode criar lógicas específicas por receita
	for req in recipe.ingredient_requirements:
		var id = req.ingredient_id
		var step = ""

		match req.state:
			"cut":
				step = "- Cortar %s" % id
			"fried":
				step = "- Fritar %s" % id
			"cooked":
				step = "- Cozinhar %s" % id
			_:
				step = "- Usar %s" % id

		steps += step + "\n"

	steps += "Montar no prato e entregar ao cliente."
	return "Modo de preparo:\n" + steps.strip_edges()
