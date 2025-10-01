extends Node

# Arraste todos os IngredientData aqui no Inspector
@export var ingredient_list: Array[IngredientData] = []

var ingredients: Dictionary[String, IngredientData] = {}

func _ready() -> void:
	ingredients.clear()
	if not ingredient_list.is_empty():
		for d in ingredient_list:
			if d and d is IngredientData and d.id != "":
				ingredients[d.id] = d
	else:
		push_warning("⚠️ IngredientDatabase: nenhuma ingredient_list atribuída no Inspector!")

func get_ingredient(id: String) -> IngredientData:
	return ingredients.get(id, null)

func get_sprite(id: String, state: String) -> Texture2D:
	var data := get_ingredient(id)
	if data:
		return data.states.get(state, null)
	return null
