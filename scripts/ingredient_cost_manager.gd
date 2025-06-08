extends Node

# Tabela de precos em Miaus por ingrediente
const INGREDIENT_COSTS := {
	"queijo": 6,
	"mortadela": 4,
	"presunto": 5,
	"pao": 2,
	"pao de queijo": 3,
	"manteiga": 2,
	"ovo": 2,
	"arroz": 3,
	"feijao": 3,
	"carne": 7,
	"peixe": 6,
	"farofa": 2,
	"cuscuz": 4,
	"batata": 3,
	"pimentao": 2
}

func get_cost(ingredient_id: String) -> int:
	return INGREDIENT_COSTS.get(ingredient_id, 0)

func charge_for_ingredient(main_scene: Node, ingredient_id: String, quantity: int = 1) -> void:
	var total_cost := get_cost(ingredient_id) * quantity
	main_scene.total_ingredient_expense += total_cost
	main_scene.add_money(-total_cost)
