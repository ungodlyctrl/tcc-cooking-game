extends Node

## Gerenciador de receitas sorteáveis por horário, dia e região.

var all_recipes: Array[RecipeResource] = []


func _ready() -> void:
	var dir := DirAccess.open("res://resources/recipes/")
	if not dir:
		push_warning("❗ Não foi possível abrir a pasta de receitas.")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var recipe := load("res://resources/recipes/" + file_name)
			if recipe is RecipeResource:
				all_recipes.append(recipe)
		file_name = dir.get_next()
	dir.list_dir_end()


## Retorna receitas válidas para o dia, região e horário
func get_available_recipes(current_day: int, region: String, time_of_day: String) -> Array[RecipeResource]:
	var valid: Array[RecipeResource] = []
	for recipe in all_recipes:
		if not (recipe is RecipeResource):
			continue
		if recipe.region != region:
			continue
		if not time_of_day in recipe.time_of_day:
			continue
		if current_day < recipe.min_day:
			continue
		valid.append(recipe)
	return valid


## Sorteia uma receita e aplica variações
func get_random_recipe(current_day: int, region: String, time_of_day: String) -> Dictionary:
	var pool := get_available_recipes(current_day, region, time_of_day)
	if pool.is_empty():
		push_warning("Nenhuma receita válida para %s (%s) - Dia %d" % [region, time_of_day, current_day])
		return {}
	
	var base_recipe: RecipeResource = pool.pick_random()
	return apply_variations(base_recipe)


## Aplica variações (opcionais, quantidades etc.)
## Retorna dicionário com { "recipe": RecipeResource, "variants": Array, "client_lines": Array }
func apply_variations(recipe: RecipeResource) -> Dictionary:
	var clone := recipe.duplicate(true) as RecipeResource
	var final_reqs: Array[IngredientRequirement] = []
	var variants: Array[Dictionary] = []
	var variation_lines: Array[String] = []

	for req in recipe.ingredient_requirements:
		if req == null:
			continue

		var included := true
		var final_qty := req.quantity

		if req.optional:
			if randf() > req.inclusion_chance:
				included = false

		if included:
			if not req.variation_quantity_options.is_empty():
				final_qty = _pick_weighted(req.variation_quantity_options, req.variation_quantity_weights)

			var new_req := req.duplicate(true) as IngredientRequirement
			new_req.quantity = final_qty
			final_reqs.append(new_req)

		# registra variação aplicada
		variants.append({
			"id": req.ingredient_id,
			"included": included,
			"quantity": final_qty
		})

		# gera falas de acordo com variação
		if not included and not req.variation_line_absent.is_empty():
			variation_lines.append(req.variation_line_absent.pick_random())
		elif final_qty > 1 and not req.variation_line_quantity.is_empty():
			variation_lines.append(req.variation_line_quantity.pick_random())

	clone.ingredient_requirements = final_reqs

	# 🔥 monta falas finais: sempre começa com a fala base
	var final_lines: Array[String] = []
	if not recipe.client_lines.is_empty():
		final_lines.append(recipe.client_lines.pick_random())  # fala base
	final_lines.append_array(variation_lines)  # depois as falas de variação (se houver)

	# fallback se nem fala base existir (caso extremo)
	if final_lines.is_empty():
		final_lines.append("...")

	return {
		"recipe": clone,
		"variants": variants,
		"client_lines": final_lines
	}


## Sorteio ponderado (suporta weights opcionais)
func _pick_weighted(options: Array, weights: Array) -> Variant:
	if weights.is_empty() or options.size() != weights.size():
		return options.pick_random()

	var total := 0.0
	for w in weights:
		total += w

	var r := randf() * total
	var accum := 0.0
	for i in range(options.size()):
		accum += weights[i]
		if r <= accum:
			return options[i]

	return options.back()
