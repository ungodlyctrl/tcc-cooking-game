extends Resource
class_name RecipeResource

## Dados completos de uma receita usada no jogo.
## Define nome, região, ingredientes, imagem, falas e restrições de tempo/dia.

@export var recipe_name: String = ""
@export var region: String = ""

@export var base_price: int = 100
@export var icon: Texture2D

@export var min_day: int = 1
@export var time_of_day: Array[String] = ["breakfast", "lunch", "dinner"]

@export var ingredient_requirements: Array[IngredientRequirement] = []
@export var client_lines: Array[String] = []  # Falas genéricas
