extends Resource
class_name IngredientRequirement

@export var ingredient_id: String = ""
@export var state: String = "raw"

enum Stage {
	NONE,
	CUTTING,
	COOKING,
	FRYING,
	MIXING
}
@export var stages: Array[Stage] = []

@export var quantity: int = 1
@export var optional: bool = false
@export var inclusion_chance: float = 1.0

## Suporte a quantidades variáveis
@export var variation_quantity_options: Array[int] = []
@export var variation_quantity_weights: Array[float] = []  ## mesmo tamanho de options

# Fala se o ingrediente for OMITIDO
@export var variation_line_absent: Array[String] = []

# Fala se o ingrediente for INCLUÍDO com mais de 1 unidade
@export var variation_line_quantity: Array[String] = []
