extends Control
class_name ModeAttendance

# Label onde será exibida a fala do cliente
@onready var dialogue_label: RichTextLabel = $DialogueBox/MarginContainer/RichTextLabel

# Receita atual a ser exibida nesse atendimento
var current_recipe: RecipeResource


## Define a receita do pedido atual e exibe a fala do cliente
func set_recipe(recipe: RecipeResource) -> void:
	current_recipe = recipe

	# Aqui pegamos os ingredientes opcionais que foram incluídos
	var optional_variants: Array[Dictionary] = []

	for req in current_recipe.ingredient_requirements:
		if req.optional and req.quantity > 0:
			optional_variants.append({
				"id": req.ingredient_id,
				"quantity": req.quantity
			})

	# Agora passamos a lista completa dos ingredientes opcionais incluídos
	var line: String = current_recipe.get_random_client_line(optional_variants)
	dialogue_label.text = line


## Ao clicar no botão de confirmação, avança para o modo de preparo
func _on_confirm_button_pressed() -> void:
	var main_scene = get_tree().current_scene as MainScene
	main_scene.prep_start_minutes = main_scene.current_time_minutes
	main_scene.switch_mode(1) #mode preparation
