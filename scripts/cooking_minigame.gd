extends Control
class_name CookingMinigame

# === Exported Variables ===
@export var tool_type: String = "frigideira"
@export var cook_speed: float = 30.0
var ingredient_data_list: Array[Dictionary] = []
var tool_global_position: Vector2 = Vector2.ZERO

# === OnReady References ===
@onready var tool_sprite: TextureRect = $ToolSprite
@onready var ingredient_sprite: TextureRect = $IngredientSprite
@onready var heat_marker: Control = $HeatBar/HeatMarker
@onready var heat_bar: Control = $HeatBar
@onready var zone_cool: Control = $HeatBar/ZoneCool
@onready var zone_ideal: Control = $HeatBar/ZoneIdeal
@onready var zone_burn: Control = $HeatBar/ZoneBurn
@onready var feedback: Label = $FeedbackLabel

# === Internal State ===
var is_cooking: bool = true
var marker_end: int = 0
var result: String = ""


func _ready() -> void:
	global_position = tool_global_position  # ← Centraliza na posição da ferramenta original
	marker_end = heat_bar.size.x - heat_marker.size.x
	heat_marker.position.x = 0
	set_process(true)
	is_cooking = true
	_load_textures()


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
	_spawn_result_ingredients()
	queue_free()


func _spawn_result_ingredients() -> void:
	var cooked_tool_scene := preload("res://scenes/ui/cooked_tool.tscn")
	var cooked_tool := cooked_tool_scene.instantiate() as CookedTool

	if cooked_tool == null:
		push_error("❌ cooked_tool.tscn não está corretamente configurada com o script CookedTool.gd!")
		return

	cooked_tool.tool_type = tool_type

	var final_state := "cooked"
	if tool_type == "frigideira":
		final_state = "fried"

	var cook_result: String = ""

	if result == "✅ No ponto!":
		cook_result = "perfect"
	elif result in ["🔥 Queimado", "❌ Queimado!"]:
		cook_result = "burnt"
	elif result == "🧊 Cru":
		cook_result = "raw"
	elif result == "😐 Mais ou menos":
		cook_result = "meh"
	else:
		cook_result = "unknown"

	var result_ingredients: Array[Dictionary] = []

	for data in ingredient_data_list:
		if data.has("id"):
			result_ingredients.append({
				"id": data["id"],
				"state": final_state,
				"result": cook_result
			})

	cooked_tool.cooked_ingredients = result_ingredients

	var prep_area := get_tree().current_scene.get_node("Mode_Preparation/ScrollContainer/PrepArea")
	prep_area.add_child(cooked_tool)
	cooked_tool.global_position = tool_global_position



func _load_textures() -> void:
	# Tool visual
	tool_sprite.texture = load("res://assets/utensilios/%s.png" % tool_type)

	# Carrega o sprite do primeiro ingrediente (se existir) usando o IngredientDatabase
	if ingredient_data_list.size() > 0:
		var first_id = ingredient_data_list[0].get("id", "")
		if first_id != "":
			var state : String = ingredient_data_list[0].get("state", "raw")
			var sprite_path := IngredientDatabase.get_sprite_path(first_id, state)

			if sprite_path != "":
				ingredient_sprite.texture = load(sprite_path)
			else:
				print("⚠️ Sprite não encontrado para %s (%s)" % [first_id, state])
