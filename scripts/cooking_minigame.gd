extends Control
class_name CookingMinigame

signal finished(result_ingredients: Array[Dictionary], tool_type: String, quality: String)

# ---------------- Export ----------------
@export var tool_type: String = ""   # definido pelo BurnerSlot
@export var cook_speed: float = 30.0
@export var show_background: bool = false

# ---------------- Estado ----------------
var ingredient_data_list: Array[Dictionary] = []
var is_cooking: bool = true
var marker_end: float = 0.0
var result_label: String = ""

# ---------------- Referência ----------------
var anchor: Control = null
var ingredient_list_label: Label

# ---------------- Onready ----------------
@onready var tool_sprite: TextureRect = $ToolSprite
@onready var ingredient_sprite: TextureRect = $IngredientSprite
@onready var heat_marker: Control = $HeatBar/HeatMarker
@onready var heat_bar: Control = $HeatBar
@onready var zone_cool: Control = $HeatBar/ZoneCool
@onready var zone_ideal: Control = $HeatBar/ZoneIdeal
@onready var zone_burn: Control = $HeatBar/ZoneBurn
@onready var feedback: Label = $FeedbackLabel
@onready var background: CanvasItem = $Background


## Chamado pelo BurnerSlot para fixar o minigame na boca do fogão
func attach_to_anchor(node: Control) -> void:
	anchor = node
	global_position = anchor.global_position   # usa o canto superior esquerdo da âncora


func _ready() -> void:
	ingredient_list_label = get_node_or_null("IngredientListLabel")
	if ingredient_list_label:
		ingredient_list_label.text = ""

	if background:
		background.visible = show_background

	# inicialização da barra
	marker_end = float(heat_bar.size.x - heat_marker.size.x)
	heat_marker.position.x = 0.0
	is_cooking = true
	set_process(true)
	tool_sprite.mouse_filter = Control.MOUSE_FILTER_STOP
	tool_sprite.gui_input.connect(_on_tool_clicked)

	# Carrega sprites iniciais
	_load_textures()


func initialize(t_type: String, ingredients: Array[Dictionary]) -> void:
	tool_type = t_type
	ingredient_data_list = ingredients
	_load_textures()


func _process(delta: float) -> void:
	if not is_cooking:
		return

	heat_marker.position.x = minf(heat_marker.position.x + cook_speed * delta, marker_end)

	if is_cooking and is_equal_approx(heat_marker.position.x, marker_end):
		is_cooking = false
		_show_result("❌ Queimado!")


func _gui_input(event: InputEvent) -> void:
	if not is_cooking:
		return

	if event is InputEventMouseButton and event.pressed:
		is_cooking = false
		_evaluate_cook()


func _on_tool_clicked(event: InputEvent) -> void:
	if not is_cooking:
		return
	if event is InputEventMouseButton and event.pressed:
		is_cooking = false
		_evaluate_cook()


func _evaluate_cook() -> void:
	var x := heat_marker.position.x
	var ideal_start := zone_ideal.position.x
	var ideal_end := ideal_start + zone_ideal.size.x
	var cool_end := zone_cool.position.x + zone_cool.size.x
	var burn_start := zone_burn.position.x

	if x >= ideal_start and x <= ideal_end:
		result_label = "✅ No ponto!"
	elif x < cool_end:
		result_label = "🧊 Cru"
	elif x > burn_start:
		result_label = "🔥 Queimado"
	else:
		result_label = "😐 Mais ou menos"

	_show_result(result_label)


func _show_result(text: String) -> void:
	feedback.text = text
	await get_tree().create_timer(1.0).timeout

	var quality := _label_to_quality(result_label)
	var final_state: String = "fried" if tool_type == "frigideira" else "cooked"

	var out: Array[Dictionary] = []
	for d in ingredient_data_list:
		var id: String = d.get("id", "")
		if id == "":
			continue
		out.append({
			"id": id,
			"state": final_state,
			"result": quality
		})

	finished.emit(out, tool_type, quality)
	queue_free()


func _label_to_quality(label: String) -> String:
	match label:
		"✅ No ponto!":
			return "perfect"
		"🔥 Queimado", "❌ Queimado!":
			return "burnt"
		"🧊 Cru":
			return "raw"
		"😐 Mais ou menos":
			return "meh"
		_:
			return "unknown"


# ------------------------
# Visual / utilitários
# ------------------------
func _load_textures() -> void:
	# Sprite da ferramenta
	if tool_type != "":
		var tool_path: String = "res://assets/utensilios/%s.png" % tool_type
		tool_sprite.texture = load(tool_path)

	# Ingredientes
	if ingredient_data_list.is_empty():
		if ingredient_list_label:
			ingredient_list_label.text = "(Nenhum ingrediente)"
		return

	_build_ingredient_list_text()

	var first_id: String = ingredient_data_list[0].get("id", "")
	if first_id == "":
		return

	var st: String = ingredient_data_list[0].get("state", "raw")
	var data: IngredientData = IngredientDatabase.get_ingredient(first_id)
	if data:
		ingredient_sprite.texture = data.states.get(st, null)


func _build_ingredient_list_text() -> void:
	if not ingredient_list_label:
		return

	var parts: Array[String] = []
	for d in ingredient_data_list:
		var id: String = d.get("id", "")
		if id == "":
			continue
		var data: IngredientData = IngredientDatabase.get_ingredient(id)
		if data:
			parts.append(data.display_name.capitalize())

	ingredient_list_label.text = "Ingredientes:\n- " + ",\n- ".join(parts)
