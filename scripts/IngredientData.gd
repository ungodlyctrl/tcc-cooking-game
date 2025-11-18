extends Resource
class_name IngredientData

@export var id: String
@export var mini_icons: Array[IngredientMiniIcon] = []
@export var display_name: String
@export var min_day: int = 1
@export var container_texture: Texture2D
@export var initial_state: String = "raw"
@export var states: Dictionary[String, Texture2D] = {}
@export_enum("m", "f") var gender: String = "f"

## Offset opcional para ajustar a posição do ingrediente durante o drag.
## Exemplo: Vector2(0, -10) deixa o sprite um pouco acima do cursor.
@export var drag_offset: Vector2 = Vector2.ZERO
