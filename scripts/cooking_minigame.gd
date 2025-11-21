extends Control
class_name CookingMinigame

signal finished(result_ingredients: Array[Dictionary], tool_type: String, quality: String)

# ---------------------------------------------------------
# CONSTANTES
# ---------------------------------------------------------
const STATE_FRIED := "fried"
const STATE_COOKED := "cooked"

# ---------------------------------------------------------
# EXPORTS
# ---------------------------------------------------------
@export var tool_type: String = ""
@export var cook_speed: float = 50.0
@export var show_background: bool = false

# ---------------------------------------------------------
# NODES
# ---------------------------------------------------------
@onready var pan_anim: AnimatedSprite2D = $PanAnimation
@onready var fry_anim: AnimatedSprite2D = $FryAnimation
@onready var tool_sprite: TextureRect = $ToolSprite
@onready var mini_icons: HBoxContainer = $MiniIcons
@onready var heat_bar: Control = $HeatBar
@onready var heat_marker: Control = $HeatBar/HeatMarker
@onready var zone_cool: Control = $HeatBar/ZoneCool
@onready var zone_ideal: Control = $HeatBar/ZoneIdeal
@onready var zone_burn: Control = $HeatBar/ZoneBurn
@onready var feedback: Label = $FeedbackLabel
@onready var background: CanvasItem = $Background

# ---------------------------------------------------------
# VARIÁVEIS
# ---------------------------------------------------------
var ingredient_data_list: Array[Dictionary] = []
var is_cooking: bool = true
var marker_range: float = 0.0
var result_label: String = ""
var anchor: Control = null
var _use_vertical_axis: bool = true

var full_pan_textures := {
	"panela": preload("res://assets/utensilios/panela_full.png"),
	"frigideira": preload("res://assets/utensilios/frigideira_full.png")
}

# ---------------------------------------------------------
# ATTACH
# ---------------------------------------------------------
func attach_to_anchor(node: Control) -> void:
	anchor = node
	global_position = anchor.global_position

# ---------------------------------------------------------
# INITIALIZE
# ---------------------------------------------------------
func initialize(t_type: String, ingredients: Array[Dictionary]) -> void:
	tool_type = t_type
	ingredient_data_list = ingredients.duplicate(true)
	await get_tree().process_frame
	_setup_visuals()

# ---------------------------------------------------------
# READY
# ---------------------------------------------------------
func _ready() -> void:
	if background:
		background.visible = show_background

	await get_tree().process_frame

	var rot := int(round(heat_bar.rotation_degrees)) % 360
	_use_vertical_axis = not (abs(rot) == 90 or abs(rot) == 270)

	if _use_vertical_axis:
		marker_range = heat_bar.size.y - heat_marker.size.y
		heat_marker.position.y = marker_range
	else:
		marker_range = heat_bar.size.x - heat_marker.size.x
		heat_marker.position.x = 0.0

	set_process(true)

	gui_input.connect(_on_any_click_stop)
	tool_sprite.gui_input.connect(_on_any_click_stop)


# ---------------------------------------------------------
# SETUP VISUAL
# ---------------------------------------------------------
func _setup_visuals() -> void:

	# DESLIGA TUDO
	if pan_anim:
		pan_anim.visible = false
		pan_anim.stop()

	if fry_anim:
		fry_anim.visible = false
		fry_anim.stop()

	tool_sprite.visible = true

	# PANELA
	if tool_type == "panela":
		tool_sprite.visible = false
		pan_anim.visible = true
		pan_anim.frame = 0
		pan_anim.play("boil") # animação da panela

	# FRIGIDEIRA
	elif tool_type == "frigideira":
		tool_sprite.visible = false
		fry_anim.visible = true
		fry_anim.frame = 0
		fry_anim.play("fry") # animação da frigideira

	_refresh_mini_icons()

# ---------------------------------------------------------
# MINI ICONS
# ---------------------------------------------------------
func _refresh_mini_icons() -> void:
	for c in mini_icons.get_children():
		c.queue_free()

	for ing in ingredient_data_list:
		var id = ing.get("id", "")
		var st = ing.get("state", "")
		var tex: Texture2D = null

		if Managers and Managers.ingredient_database:
			tex = Managers.ingredient_database.get_mini_icon(id, st)

		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mini_icons.add_child(icon)

# ---------------------------------------------------------
# PROCESS
# ---------------------------------------------------------
func _process(delta: float) -> void:
	if not is_cooking:
		return

	if _use_vertical_axis:
		heat_marker.position.y = max(0.0, heat_marker.position.y - cook_speed * delta)

		if heat_marker.position.y <= 0.0:
			is_cooking = false
			_show_result("❌ Queimado!")
	else:
		heat_marker.position.x = min(marker_range, heat_marker.position.x + cook_speed * delta)

		if heat_marker.position.x >= marker_range:
			is_cooking = false
			_show_result("❌ Queimado!")

# ---------------------------------------------------------
# CLICK STOP
# ---------------------------------------------------------
func _on_any_click_stop(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and is_cooking:
		is_cooking = false
		_evaluate_cook()

# ---------------------------------------------------------
# EVALUATE
# ---------------------------------------------------------
func _evaluate_cook() -> void:
	if _use_vertical_axis:
		var pos := heat_marker.position.y
		var cool_end := zone_cool.position.y + zone_cool.size.y
		var ideal_start := zone_ideal.position.y
		var ideal_end := ideal_start + zone_ideal.size.y
		var burn_start := zone_burn.position.y

		if pos >= ideal_start and pos <= ideal_end:
			result_label = "✅ No ponto!"
		elif pos < cool_end:
			result_label = "🧊 Cru"
		elif pos > burn_start:
			result_label = "🔥 Queimado"
		else:
			result_label = "😐 Mais ou menos"

	else:
		var posx := heat_marker.position.x
		var cool_end_x := zone_cool.position.x + zone_cool.size.x
		var ideal_start_x := zone_ideal.position.x
		var ideal_end_x := ideal_start_x + zone_ideal.size.x
		var burn_start_x := zone_burn.position.x

		if posx >= ideal_start_x and posx <= ideal_end_x:
			result_label = "✅ No ponto!"
		elif posx < cool_end_x:
			result_label = "🧊 Cru"
		elif posx > burn_start_x:
			result_label = "🔥 Queimado"
		else:
			result_label = "😐 Mais ou menos"

	_show_result(result_label)

# ---------------------------------------------------------
# RESULTADO FINAL
# ---------------------------------------------------------
func _show_result(text: String) -> void:
	if feedback:
		feedback.text = text

	if pan_anim:
		pan_anim.stop()
		pan_anim.visible = false

	if fry_anim:
		fry_anim.stop()
		fry_anim.visible = false

	if tool_sprite:
		var full_tex: Texture2D = full_pan_textures.get(tool_type)
		if full_tex:
			tool_sprite.texture = full_tex
		tool_sprite.visible = true

	await get_tree().create_timer(1.0).timeout

	var quality := _label_to_quality(result_label)
	var final_state: String = ""
	if tool_type == "frigideira":
		final_state = STATE_FRIED
	else:
		final_state = STATE_COOKED

	var out: Array[Dictionary] = []

	for d in ingredient_data_list:
		var id = d.get("id", "")
		if id != "":
			out.append({
				"id": id,
				"state": final_state,
				"result": quality
			})

	finished.emit(out, tool_type, quality)
	queue_free()

# ---------------------------------------------------------
# LABEL → QUALITY
# ---------------------------------------------------------
func _label_to_quality(label: String) -> String:
	match label:
		"✅ No ponto!": return "perfect"
		"🔥 Queimado", "❌ Queimado!": return "burnt"
		"🧊 Cru": return "raw"
		"😐 Mais ou menos": return "meh"
		_: return "unknown"
