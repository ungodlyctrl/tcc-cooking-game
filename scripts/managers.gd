extends Node

var recipe_manager: RecipeManager
var ingredient_database: IngredientDatabase
var client_manager: ClientManager

func _enter_tree() -> void:
	recipe_manager = $RecipeManager
	ingredient_database = $IngredientDatabase
	client_manager = $ClientManager

@export var feedback_config: FeedbackConfig
