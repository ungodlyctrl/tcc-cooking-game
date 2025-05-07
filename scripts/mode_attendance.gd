extends Control

@onready var dialogue_label = $DialogueBox/MarginContainer/RichTextLabel

var current_recipe: Recipe

func _ready():
	current_recipe = RecipeLoader.get_random_recipe()
	var random_line = current_recipe.dialog_lines.pick_random()
	dialogue_label.text = random_line
	
func _on_confirm_button_pressed() -> void:
	get_tree().current_scene.switch_mode(1) # Vai para o modo preparo
