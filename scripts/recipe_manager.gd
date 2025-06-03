extends Node

## Gerenciador de receitas sorteáveis por horário, dia e região.

var all_recipes: Array[RecipeResource] = []


func _ready():
	var dir := DirAccess.open("res://resources/recipes/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path = "res://resources/recipes/" + file_name
				var recipe = load(path)
				if recipe is RecipeResource:
					all_recipes.append(recipe)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_warning("❗ Não foi possível abrir a pasta de receitas.")


func get_available_recipes(current_day: int, region: String, time_of_day: String) -> Array[RecipeResource]:
	var valid_recipes: Array[RecipeResource] = []

	for recipe in all_recipes:
		if not recipe is RecipeResource:
			continue

		if region != recipe.region:
			continue

		if not time_of_day in recipe.time_of_day:
			continue

		if current_day < recipe.min_day:
			continue

		valid_recipes.append(recipe)

	return valid_recipes


func get_random_recipe(current_day: int, region: String, time_of_day: String) -> RecipeResource:
	var pool = get_available_recipes(current_day, region, time_of_day)
	if pool.is_empty():
		push_warning("Nenhuma receita válida encontrada para %s (%s) - Dia %d" % [region, time_of_day, current_day])
		return null

	return pool.pick_random()
