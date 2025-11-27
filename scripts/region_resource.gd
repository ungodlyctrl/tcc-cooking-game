extends Resource
class_name RegionResource

## Identificação básica
@export var id: String = ""                 # "sudeste", "nordeste"
@export var display_name: String = ""
@export var description: String = ""

## Preço para desbloquear (na loja futuramente)
@export var unlock_price: int = 0

## Ingredientes que pertencem a essa região
@export var ingredients: Array[IngredientData] = []

## Receitas específicas dessa região (opcional; RecipeManager já filtra por recipe.region)
@export var recipes: Array[RecipeResource] = []

## Clientes dessa região
@export var clients: Array[ClientData] = []

@export var background_data: RegionBackgrounds

## Layouts de preparação específicos da região
@export var prep_layouts: Array[PrepLayoutResource] = []

## Ícone dessa região (MAPA/LOJA)
@export var icon: Texture2D
