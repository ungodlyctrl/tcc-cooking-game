extends Resource
class_name IngredientData

@export var id: String
@export var display_name: String
@export var min_day: int = 1
@export var container_texture: Texture2D
@export var initial_state: String = "raw"
@export var states: Dictionary[String, Texture2D] = {} 
## Exemplo: { "raw": Texture2D, "cut": Texture2D, "cooked": Texture2D }
