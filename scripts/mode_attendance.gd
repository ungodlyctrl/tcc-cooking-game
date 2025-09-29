extends Control
class_name ModeAttendance

@onready var dialogue_box: DialogueBox = $DialogueBox
var current_recipe: RecipeResource

func _ready() -> void:
	dialogue_box.dialogue_confirmed.connect(_on_confirm_button_pressed)

func set_recipe(recipe: RecipeResource, client_lines: Array[String] = []) -> void:
	current_recipe = recipe

	var lines: Array[String] = []
	if not client_lines.is_empty():
		lines = client_lines.duplicate()
	elif not recipe.client_lines.is_empty():
		lines.append(recipe.client_lines.pick_random())
	else:
		lines.append("...")

	dialogue_box.show_box()
	dialogue_box.set_lines(lines, true)  # 🔥 pedido novo → pode confirmar

func _on_confirm_button_pressed() -> void:
	var main_scene = get_tree().current_scene as MainScene
	main_scene.prep_start_minutes = main_scene.current_time_minutes
	main_scene.switch_mode(MainScene.GameMode.PREPARATION)

func show_feedback(text: String) -> void:
	dialogue_box.show_box()
	dialogue_box.set_lines([text], false)  # 🔥 feedback → sem confirmar

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
	var texture: Texture2D = time_backgrounds.get(visual_time_of_day, null)
	if texture == null:
		push_warning("❌ Fundo não encontrado para: " + visual_time_of_day)
	else:
		$CityBackground.texture = texture
