@icon("res://assets/icons/recipe_icon.png") # opcional, pode alterar
extends Resource
class_name RecipeData


## Representa uma receita completa do jogo, com seus ingredientes, processos e metadados.

# Nome interno (ex: "feijoada")
@export var id: String = ""

# Nome visível ao jogador (ex: "Feijoada")
@export var display_name: String = ""

# Região cultural do prato (ex: "Sudeste", "Nordeste", etc.)
@export var region: String = "sudeste"

# Período do dia em que a receita pode aparecer
enum MealTime { CAFE, ALMOCO, JANTAR }
@export var meal_time: MealTime = MealTime.ALMOCO

# Ingredientes exigidos, com estados e processos
@export var ingredients: Array[IngredientRequirement] = []

# Falas possíveis do cliente ao pedir este prato
@export var dialog_lines: Array[String] = []

# Sprite representando o prato pronto (opcional)
@export var icon_texture: Texture2D = null
