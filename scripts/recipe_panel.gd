extends Control
class_name RecipePanel

@onready var name_label: Label = $Content/NameLabel
@onready var ingredients_list: VBoxContainer = $Content/IngredientList

## Mostra as informações de uma receita no painel lateral
func show_recipe(recipe: RecipeResource) -> void:
	if recipe == null:
		hide()
		return

	name_label.text = recipe.recipe_name

	# Limpa a lista anterior
	for child in ingredients_list.get_children():
		child.queue_free()

	# Mostra todos os ingredientes, incluindo opcionais
	for req in recipe.ingredient_requirements:
		if req == null:
			continue

		var label := Label.new()
		var ingredient_name := IngredientDatabase.get_display_name(req.ingredient_id)
		var quantity_text := " x%d" % req.quantity if req.quantity > 1 else ""
		var optional_text := " (opcional)" if req.optional else ""
		
		label.text = "- %s%s%s" % [ingredient_name, quantity_text, optional_text]
		ingredients_list.add_child(label)

	show()
