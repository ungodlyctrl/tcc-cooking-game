extends Control
class_name ModeAttendance

# Label onde será exibida a fala do cliente
@onready var dialogue_label: RichTextLabel = $DialogueBox/MarginContainer/RichTextLabel

# Receita atual a ser exibida nesse atendimento
var current_recipe: RecipeResource


## Define a receita do pedido atual e exibe a fala do cliente
func set_recipe(recipe: RecipeResource) -> void:
	current_recipe = recipe

	# Obtém os IDs de ingredientes opcionais (se houver)
	var optional_ids: Array[String] = current_recipe.get_optional_ingredient_ids()

	# Sorteia uma fala com base nas variações, se houver
	var line: String = current_recipe.get_random_client_line(optional_ids)

	dialogue_label.text = line


## Ao clicar no botão de confirmação, avança para o modo de preparo
func _on_confirm_button_pressed() -> void:
	get_tree().current_scene.switch_mode(1)  # 1 = GameMode.PREPARATION
