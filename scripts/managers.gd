extends Node

var recipe_manager: RecipeManager
var ingredient_database: IngredientDatabase
var client_manager: ClientManager
var drag_manager: DragManager
var region_manager: RegionManager
var mix_manager: MixManager

@export var feedback_config: FeedbackConfig

func _enter_tree() -> void:
	recipe_manager = $RecipeManager
	ingredient_database = $IngredientDatabase
	client_manager = $ClientManager
	drag_manager = $DragManager
	region_manager = $RegionManager
	mix_manager = $MixManager
