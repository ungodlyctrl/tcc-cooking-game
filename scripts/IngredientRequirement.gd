extends Resource
class_name IngredientRequirement

## Representa um ingrediente dentro de uma receita.

# ID do ingrediente conforme definido no IngredientDatabase
@export var ingredient_id: String = ""

# Estado final esperado do ingrediente no prato
# Ex: "raw", "cut", "cooked", "fried"
@export var state: String = "raw"

# Etapas do processo esperadas (apenas informativas/guiadas, sem validação direta)
# Ex: [CUTTING, COOKING]
enum Stage {
	NONE,
	CUTTING,
	COOKING,
	FRYING,
	MIXING
}
@export var stages: Array[Stage] = []

# Quantidade exigida desse ingrediente
@export var quantity: int = 1

# Se o ingrediente é opcional (variação aleatória no pedido)
@export var optional: bool = false

# Frase personalizada do cliente para essa variação (ex: "Capricha no queijo!")
@export var custom_line: String = ""

# Se foi incluído na versão sorteada do pedido (preenchido dinamicamente)
var included: bool = true
