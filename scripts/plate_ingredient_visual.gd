extends Resource
class_name PlateIngredientVisual

## Define os dados visuais de um ingrediente dentro de um prato.

@export var ingredient_id: String
@export var state_sprites: Array[IngredientStateSprite] = [] # ex: {"raw": Texture2D, "cooked": Texture2D}
@export var offset: Vector2 = Vector2.ZERO
@export var z_index: int = 0
