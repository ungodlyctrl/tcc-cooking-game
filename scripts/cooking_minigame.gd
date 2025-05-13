extends Control

@export var ingredient_name := "cenoura"
@export var tool_type := "frigideira"  # ou "panela"

@onready var tool_sprite := $ToolSprite
@onready var ingredient_sprite := $IngredientSprite
@onready var heat_marker := $HeatBar/HeatMarker
@onready var zone_cool := $HeatBar/ZoneCool
@onready var zone_ideal := $HeatBar/ZoneIdeal
@onready var zone_burn := $HeatBar/ZoneBurn
@onready var feedback := $FeedbackLabel

var cook_speed := 30.0  # pixels por segundo
var is_cooking := true
var marker_start := 0
var marker_end := 169 # largura da barra - largura do marcador
var result: String

func _ready():
	_load_textures()
	heat_marker.position.x = marker_start
	is_cooking = true
	set_process(true)

func _process(delta):
	if not is_cooking:
		return

	heat_marker.position.x += cook_speed * delta

	if heat_marker.position.x >= marker_end:
		heat_marker.position.x = marker_end
		is_cooking = false
		_show_result("❌ Queimado!")
		return

func _gui_input(event):
	if !is_cooking:
		return

	if event is InputEventMouseButton and event.pressed:
		print("🖱️ gui_input clique detectado")
		is_cooking = false
		_evaluate_cook()

func _evaluate_cook():
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

func _spawn_result_ingredient():
	var scene := preload("res://scenes/ui/ingredient.tscn")
	var ingredient := scene.instantiate()

	ingredient.ingredient_id = ingredient_name
	ingredient.state = "fried" if tool_type == "frigideira" else "cooked"

	# Posicionar em cima do fogão (fixo na bancada)
	var parent := get_tree().current_scene.get_node("Mode_Preparation/ScrollContainer/PrepArea")
	parent.add_child(ingredient)

	# Posiciona visualmente próximo do fogão
	ingredient.position = self.position + Vector2(0, 40)

func _show_result(text: String):
	feedback.text = text
	await get_tree().create_timer(1.2).timeout
	_spawn_result_ingredient()
	queue_free()

func _load_textures():
	tool_sprite.texture = load("res://assets/utensilios/%s.png" % tool_type)
	ingredient_sprite.texture = load("res://assets/ingredientes/%s.png" % ingredient_name)
