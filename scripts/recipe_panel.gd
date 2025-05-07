extends VBoxContainer

@onready var toggle_button := $ToggleButton
@onready var content := $Content
@onready var name_label := $Content/NameLabel
@onready var step_list := $Content/StepList
@onready var ingredient_list := $Content/IngredientList

var is_expanded := false

func _ready():
	toggle_button.pressed.connect(_on_toggle_pressed)
	content.visible = false
	toggle_button.text = "!!"

func _on_toggle_pressed():
	is_expanded = !is_expanded
	content.visible = is_expanded
	toggle_button.text = "<--" if is_expanded else "!!"

func show_recipe(recipe: Resource):
	name_label.text = recipe.name

	for child in step_list.get_children():
		child.queue_free()
	for child in ingredient_list.get_children():
		child.queue_free()

	for step in recipe.steps:
		var step_label = Label.new()
		step_label.text = "- " + step.capitalize()
		step_list.add_child(step_label)

	for ing in recipe.ingredients_required:
		var ing_label = Label.new()
		ing_label.text = "- " + ing.capitalize()
		ingredient_list.add_child(ing_label)
