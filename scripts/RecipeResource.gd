extends Resource
class_name RecipeResource

## Dados completos de uma receita usada no jogo.
## Define nome, região, ingredientes, imagem, falas e restrições de tempo/dia.

@export var recipe_name: String = ""
@export var region: String = ""

@export var icon: Texture2D
# Ícone ilustrativo da receita, exibido na interface

@export var min_day: int = 1
# A receita só poderá ser sorteada a partir deste dia

@export var time_of_day: Array[String] = ["breakfast", "lunch", "dinner"]
# Define em quais horários essa receita pode ser sorteada

@export var ingredient_requirements: Array[IngredientRequirement] = []
# Lista de ingredientes necessários (com estado, etapa, se é opcional e quantidade)

@export var client_lines: Array[String] = []
# Falas genéricas do cliente para essa receita

# --- Funções de utilidade ---

func get_all_required_ingredients() -> Array[String]:
	var required: Array[String] = []
	for req in ingredient_requirements:
		if req != null and not req.optional:
			required.append(req.ingredient_id)
	return required


func get_optional_ingredient_ids() -> Array[String]:
	var optional: Array[String] = []
	for req in ingredient_requirements:
		if req != null and req.optional:
			optional.append(req.ingredient_id)
	return optional


func get_all_ingredient_ids() -> Array[String]:
	var all: Array[String] = []
	for req in ingredient_requirements:
		if req != null:
			all.append(req.ingredient_id)
	return all


func apply_variations() -> RecipeResource:
	var clone := self.duplicate() as RecipeResource
	var final_ingredients: Array[IngredientRequirement] = []

	for req in clone.ingredient_requirements:
		if req == null:
			continue

		if req.optional:
			# Decide inclusão com base na chance
			if randf() > req.inclusion_chance:
				continue  # Não incluir essa variação

			# Decide quantidade aleatória (se definido)
			if req.variation_quantity_options.size() > 0:
				req.quantity = req.variation_quantity_options.pick_random()

		final_ingredients.append(req)

	clone.ingredient_requirements = final_ingredients
	return clone

# --- Fala do cliente baseada nas variações aplicadas (ingredientes ativos) ---

func get_random_client_line(active_ingredients: Array[Dictionary]) -> String:
	for req in ingredient_requirements:
		if req == null or not req.optional:
			continue

		var included := active_ingredients.any(func(item):
			return item.has("id") and item["id"] == req.ingredient_id
		)

		if not included and not req.variation_line_absent.is_empty():
			return req.variation_line_absent.pick_random()

		if included:
			var found = active_ingredients.filter(func(item):
				return item.has("id") and item["id"] == req.ingredient_id
			)

			if found.size() > 0:
				var used_qty : int = found[0].get("quantity", 1)
				if used_qty > req.quantity and not req.variation_line_quantity.is_empty():
					return req.variation_line_quantity.pick_random()

	# Se nenhuma variação for usada, retorna linha genérica
	return client_lines.pick_random() if not client_lines.is_empty() else "..."
