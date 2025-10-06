extends Node

## Lista de todas as receitas disponíveis (.tres)
@export var all_recipes: Array[RecipeResource] = []

## Guarda a última receita realmente sorteada (para evitar repetição imediata)
var last_recipe_id: String = ""
## Guarda as últimas receitas sorteadas por período do dia (para evitar repetições dentro da manhã, almoço, jantar)
var recent_recipes_by_period: Dictionary = {
	"breakfast": [],
	"lunch": [],
	"dinner": []
}

## Quantas receitas manter em memória por período
const MAX_RECENT_RECIPES_PER_PERIOD: int = 2



func _ready() -> void:
	if all_recipes.is_empty():
		push_warning("⚠️ RecipeManager: nenhuma receita atribuída no Inspector!")
	else:
		print("RecipeManager carregou %d receitas" % all_recipes.size())


# ---------------- Filtragem ----------------
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


# ---------------- Sorteio de Receita ----------------
func get_random_recipe(current_day: int, region: String, time_of_day: String) -> Dictionary:
	var pool: Array[RecipeResource] = get_available_recipes(current_day, region, time_of_day)
	if pool.is_empty():
		push_warning("Nenhuma receita válida para %s (%s) - Dia %d" % [region, time_of_day, current_day])
		return {}

	# 🔹 evita repetir receitas recentes nesse mesmo período (ex: várias manhãs seguidas iguais)
	var recent : Array = recent_recipes_by_period.get(time_of_day, [])
	var available := []
	for r in pool:
		if r.resource_path not in recent:
			available.append(r)

	# se todas estão em 'recent', libera o pool completo de novo
	if available.is_empty():
		available = pool.duplicate()

	var chosen: RecipeResource = available.pick_random()

	# registra no histórico desse período
	recent.append(chosen.resource_path)
	if recent.size() > MAX_RECENT_RECIPES_PER_PERIOD:
		recent.pop_front()
	recent_recipes_by_period[time_of_day] = recent

	last_recipe_id = chosen.resource_path

	return apply_variations(chosen)



# ---------------- Aplicação de Variações ----------------
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

		# 🔹 Inclusão opcional
		if req.optional:
			if randf() > req.inclusion_chance:
				included = false

		# 🔹 Aplica variação de quantidade
		if included:
			if not req.variation_quantity_options.is_empty():
				final_qty = _pick_weighted(req.variation_quantity_options, req.variation_quantity_weights)

			var new_req := req.duplicate(true) as IngredientRequirement
			new_req.quantity = final_qty
			final_reqs.append(new_req)

		variants.append({
			"id": req.ingredient_id,
			"included": included,
			"quantity": final_qty
		})

		# 🔹 Linhas de variação do cliente
		if not included and not req.variation_line_absent.is_empty():
			variation_lines.append(req.variation_line_absent.pick_random())
		elif final_qty > 1 and not req.variation_line_quantity.is_empty():
			variation_lines.append(req.variation_line_quantity.pick_random())

	clone.ingredient_requirements = final_reqs

	# 🔹 Linhas de fala do cliente
	var final_lines: Array[String] = []
	if not recipe.client_lines.is_empty():
		final_lines.append(recipe.client_lines.pick_random())
	final_lines.append_array(variation_lines)
	if final_lines.is_empty():
		final_lines.append("...")

	return {
		"recipe": clone,
		"variants": variants,
		"client_lines": final_lines
	}


# ---------------- Sorteio Ponderado ----------------
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
