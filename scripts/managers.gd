extends Node

var recipe_manager: RecipeManager
var ingredient_database: IngredientDatabase
var client_manager: ClientManager
var drag_manager: DragManager    # ← ✅ novo

@export var feedback_config: FeedbackConfig

func _enter_tree() -> void:
	recipe_manager = $RecipeManager
	ingredient_database = $IngredientDatabase
	client_manager = $ClientManager
	drag_manager = $DragManager     # ← ✅ referencia o nó dentro da cena Managers
