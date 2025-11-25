extends Resource
class_name MixResource

## ID único da mistura (usado para referência no RecipeResource)
@export var mix_id: String = ""

## Ingredientes necessários para formar a mistura
## Exemplo: [{id:"batata", state:"raw"}, {id:"bacalhau", state:"raw"}]
@export var required_ingredients: Array[MixIngredient] = []

## Sprite final da mistura (a imagem única que aparecerá no prato)
@export var final_sprite: Texture2D

## Nome opcional (ex.: “Massa de bolinho de bacalhau”)
@export var display_name: String = ""
