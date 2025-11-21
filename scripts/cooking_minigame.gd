extends Control
class_name CookingMinigame

signal finished(result_ingredients: Array[Dictionary], tool_type: String, quality: String)

const STATE_FRIED := "fried"
const STATE_COOKED := "cooked"

@export var tool_type: String = ""
@export var cook_speed: float = 50.0
@export var show_background: bool = false

@onready var pan_anim: AnimatedSprite2D = $PanAnim
@onready var tool_sprite: TextureRect = $ToolSprite
@onready var mini_icons: HBoxContainer = $MiniIcons
@onready var heat_bar: Control = $HeatBar
@onready var heat_marker: Control = $HeatBar/HeatMarker
@onready var zone_cool: Control = $HeatBar/ZoneCool
@onready var zone_ideal: Control = $HeatBar/ZoneIdeal
@onready var zone_burn: Control = $HeatBar/ZoneBurn
@onready var feedback: Label = $FeedbackLabel
@onready var background: CanvasItem = $Background

var ingredient_data_list: Array[Dictionary] = []
var is_cooking := true
var marker_range := 0.0
var result_label := ""
var anchor: Control = null

var full_pan_textures := {
	"panela": preload("res://assets/utensilios/panela_full.png"),
	"frigideira": preload("res://assets/utensilios/frigideira_full.png")
}


func attach_to_anchor(node: Control) -> void:
	anchor = node
	global_position = anchor.global_position


func initialize(t_type: String, ingredients: Array[Dictionary]) -> void:
	tool_type = t_type
	ingredient_data_list = ingredients.duplicate(true)
	_setup_visuals()


func _ready() -> void:
	if background:
		background.visible = show_background

	_setup_visuals()

	await get_tree().process_frame
	marker_range = heat_bar.size.y - heat_marker.size.y
	heat_marker.position.y = marker_range

	set_process(true)

	gui_input.connect(_on_any_click_stop)
	if tool_sprite:
		tool_sprite.gui_input.connect(_on_any_click_stop)
	if pan_anim:
		pan_anim.gui_input.connect(_on_any_click_stop)



# ============================================================
# VISUAL SETUP
# ============================================================
func _setup_visuals() -> void:

	if pan_anim:
		if pan_anim.frames and pan_anim.frames.get_animation_names().has("boil"):
			pan_anim.animation = "boil"
		else:
			var names = pan_anim.frames.get_animation_names()
			if names.size() > 0:
				pan_anim.animation = names[0]
		pan_anim.visible = true
		pan_anim.play()

	if tool_sprite:
		tool_sprite.visible = false

	_refresh_mini_icons()



func _refresh_mini_icons() -> void:
	for c in mini_icons.get_children():
		c.queue_free()

	for ing in ingredient_data_list:
		var id = ing.get("id", "")
		var st = ing.get("state", "")
		var tex = null

		if Managers and Managers.ingredient_database:
			tex = Managers.ingredient_database.get_mini_icon(id, st)

		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mini_icons.add_child(icon)



# ============================================================
# PROCESS
# ============================================================
func _process(delta: float) -> void:
	if not is_cooking:
		return

	var new_y := heat_marker.position.y - cook_speed * delta
	heat_marker.position.y = max(0.0, new_y)

	if heat_marker.position.y <= 0.0:
		is_cooking = false
		_show_result("❌ Queimado!")



# ============================================================
# STOP ON CLICK
# ============================================================
func _on_any_click_stop(event: InputEvent) -> void:
	if not is_cooking:
		return
	if event is InputEventMouseButton and event.pressed:
		is_cooking = false
		_evaluate_cook()



# ============================================================
# EVALUATE RESULT
# ============================================================
func _evaluate_cook() -> void:
	var y := heat_marker.position.y

	var cool_end := zone_cool.size.y
	var ideal_start := zone_ideal.position.y
	var ideal_end := ideal_start + zone_ideal.size.y
	var burn_start := zone_burn.position.y

	if y >= ideal_start and y <= ideal_end:
		result_label = "✅ No ponto!"
	elif y < cool_end:
		result_label = "🧊 Cru"
	elif y > burn_start:
		result_label = "🔥 Queimado"
	else:
		result_label = "😐 Mais ou menos"

	_show_result(result_label)



# ============================================================
# SHOW RESULT
# ============================================================
func _show_result(text: String) -> void:
	feedback.text = text

	if pan_anim:
		pan_anim.stop()
		pan_anim.visible = false

	if tool_sprite:
		var full_tex = full_pan_textures.get(tool_type, null)
		if full_tex:
			tool_sprite.texture = full_tex
		tool_sprite.visible = true

	await get_tree().create_timer(1.0).timeout

	var quality := _label_to_quality(result_label)

	var final_state := ""
	if tool_type == "frigideira":
		final_state = STATE_FRIED
	else:
		final_state = STATE_COOKED

	var out: Array[Dictionary] = []
	for d in ingredient_data_list:
		var id = d.get("id", "")
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
		"✅ No ponto!": return "perfect"
		"🔥 Queimado", "❌ Queimado!": return "burnt"
		"🧊 Cru": return "raw"
		"😐 Mais ou menos": return "meh"
		_: return "unknown"
