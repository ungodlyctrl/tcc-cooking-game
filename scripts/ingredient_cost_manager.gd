extends Node

# Tabela de precos em Miaus por ingrediente
const INGREDIENT_COSTS := {
	"queijo": 6,
	"mortadela": 4,
	"presunto": 5,
	"pao": 2,
	"pao de queijo": 2,
	"manteiga": 2,
	"ovo": 2,
	"arroz": 3,
	"feijao": 3,
	"carne": 7,
	"peixe": 6,
	"farofa": 2,
	"cuscuz": 4,
	"batata": 3,
	"pimentao": 2,
	"massa do acaraje": 6,
	"camarao": 8,
	"caranguejo": 8,
	"coco": 5,
	"feijao fradinho": 5,
	"leite de coco": 7,
	"leite condensado": 6,
	"macaxeira": 5,
	"pimenta biquinho": 6,
	"queijo coalho": 8,
	"tapioca": 5,
	"vatapa": 7,
	"vinagrete": 6,
	"alface": 3,
	"tomate": 3,
}

func get_cost(ingredient_id: String) -> int:
	return INGREDIENT_COSTS.get(ingredient_id, 0)

func charge_for_ingredient(main_scene: Node, ingredient_id: String, quantity: int = 1) -> void:
	var total_cost := get_cost(ingredient_id) * quantity
	main_scene.total_ingredient_expense += total_cost
	main_scene.add_money(-total_cost)
	main_scene.show_money_loss(total_cost)
