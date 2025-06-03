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
# Falas genéricas de cliente para essa receita

@export var variation_lines: Dictionary = {}
# Mapa: ingrediente_id => [falas específicas caso a variação tenha sido sorteada]


## Retorna os IDs dos ingredientes obrigatórios
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


## Retorna uma frase do cliente com base nas variações sorteadas
func get_random_client_line(optional_ids: Array[String]) -> String:
	for id in optional_ids:
		if variation_lines.has(id):
			var list : Array[String] = variation_lines[id]
			if list is Array and not list.is_empty():
				return list.pick_random()

	# Fallback: fala genérica
	return client_lines.pick_random() if not client_lines.is_empty() else "..."
