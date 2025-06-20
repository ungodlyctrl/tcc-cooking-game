extends Control
class_name ModeAttendance

# Label onde será exibida a fala do cliente
@onready var dialogue_label: RichTextLabel = $DialogueBox/MarginContainer/RichTextLabel

# Receita atual a ser exibida nesse atendimento
var current_recipe: RecipeResource


## Define a receita do pedido atual e exibe a fala do cliente
func set_recipe(recipe: RecipeResource) -> void:
	current_recipe = recipe
	
	# Aqui pegamos os ingredientes opcionais que foram incluídos
	var optional_variants: Array[Dictionary] = []

	for req in current_recipe.ingredient_requirements:
		if req.optional and req.quantity > 0:
			optional_variants.append({
				"id": req.ingredient_id,
				"quantity": req.quantity
			})

	# Agora passamos a lista completa dos ingredientes opcionais incluídos
	var line: String = current_recipe.get_random_client_line(current_recipe.applied_variants)
	dialogue_label.text = line


## Ao clicar no botão de confirmação, avança para o modo de preparo
func _on_confirm_button_pressed() -> void:
	var main_scene = get_tree().current_scene as MainScene
	main_scene.prep_start_minutes = main_scene.current_time_minutes
	main_scene.switch_mode(1) #mode preparation


func show_feedback(text: String) -> void:
	dialogue_label.text = text

func hide_client() -> void:
	$AnimationPlayer.play("client_exit")
	await $AnimationPlayer.animation_finished
	$ClientSprite.visible = false
	
	var main = get_tree().current_scene as MainScene
	main.load_new_recipe()

var time_backgrounds := {
	"morning": preload("res://assets/backgrounds/city_morning.png"),
	"afternoon": preload("res://assets/backgrounds/city_afternoon.png"),
	"night": preload("res://assets/backgrounds/city_night.png")
}

func update_city_background(visual_time_of_day: String) -> void:
	print("⌛ Atualizando fundo para:", visual_time_of_day)
	var texture : Texture2D = time_backgrounds.get(visual_time_of_day, null)
	if texture == null:
		push_warning("❌ Fundo não encontrado para: " + visual_time_of_day)
	else:
		$CityBackground.texture = texture
	
