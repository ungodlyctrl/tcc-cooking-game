extends Control
class_name CookingMinigame

# === Exported Variables ===
@export var ingredient_name: String = "cenoura"
@export var tool_type: String = "frigideira"  # ou "panela"
@export var cook_speed: float = 30.0  # pixels por segundo

# === OnReady References ===
@onready var tool_sprite: TextureRect = $ToolSprite
@onready var ingredient_sprite: TextureRect = $IngredientSprite
@onready var heat_marker: Control = $HeatBar/HeatMarker
@onready var heat_bar: Control = $HeatBar
@onready var zone_cool: Control = $HeatBar/ZoneCool
@onready var zone_ideal: Control = $HeatBar/ZoneIdeal
@onready var zone_burn: Control = $HeatBar/ZoneBurn
@onready var feedback: Label = $FeedbackLabel

# === Internal Variables ===
var is_cooking := true
var marker_end := 0
var result: String = ""


func _ready() -> void:
	# Define até onde o marcador pode ir com base no tamanho da barra
	marker_end = heat_bar.size.x - heat_marker.size.x

	_load_textures()
	heat_marker.position.x = 0
	set_process(true)
	is_cooking = true


func _process(delta: float) -> void:
	if not is_cooking:
		return

	heat_marker.position.x += cook_speed * delta

	if heat_marker.position.x >= marker_end:
		heat_marker.position.x = marker_end
		is_cooking = false
		_show_result("❌ Queimado!")


func _gui_input(event: InputEvent) -> void:
	if not is_cooking:
		return

	if event is InputEventMouseButton and event.pressed:
		is_cooking = false
		_evaluate_cook()


func _evaluate_cook() -> void:
	var marker_x = heat_marker.position.x

	var ideal_start = zone_ideal.position.x
	var ideal_end = ideal_start + zone_ideal.size.x

	var cool_end = zone_cool.position.x + zone_cool.size.x
	var burn_start = zone_burn.position.x

	if marker_x >= ideal_start and marker_x <= ideal_end:
		result = "✅ No ponto!"
	elif marker_x < cool_end:
		result = "🧊 Cru"
	elif marker_x > burn_start:
		result = "🔥 Queimado"
	else:
		result = "😐 Mais ou menos"

	_show_result(result)


func _show_result(text: String) -> void:
	feedback.text = text
	await get_tree().create_timer(1.2).timeout
	_spawn_result_ingredient()
	queue_free()


func _spawn_result_ingredient() -> void:
	var ingredient := preload("res://scenes/ui/ingredient.tscn").instantiate()
	ingredient.ingredient_id = ingredient_name

	match tool_type:
		"frigideira":
			ingredient.state = "fried"
		"panela":
			ingredient.state = "cooked"
		_:
			ingredient.state = "cooked"

	var prep_area := get_tree().current_scene.get_node("Mode_Preparation/ScrollContainer/PrepArea")
	prep_area.add_child(ingredient)
	ingredient.position = self.position + Vector2(0, 40)


func _load_textures() -> void:
	tool_sprite.texture = load("res://assets/utensilios/%s.png" % tool_type)
	ingredient_sprite.texture = load("res://assets/ingredientes/%s.png" % ingredient_name)
