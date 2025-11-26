extends Control
class_name CookingMinigame

signal finished(result_ingredients: Array[Dictionary], tool_type: String, quality: String)

const STATE_FRIED := "fried"
const STATE_COOKED := "cooked"

@export var tool_type: String = ""
@export var cook_speed: float = 50.0
@export var show_background: bool = false

# NODES (ajuste se seu node tiver nomes diferentes)
@onready var pan_anim: AnimatedSprite2D = $PanAnimation
@onready var fry_anim: AnimatedSprite2D = $FryAnimation

@onready var pan_area: Area2D = $PanArea
@onready var fry_area: Area2D = $FryArea
# cada Area2D deve ter um filho CollisionShape2D chamado "CollisionShape2D"

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
var _use_vertical_axis := true

var full_pan_textures := {
	"panela": preload("res://assets/utensilios/panela_full.png"),
	"frigideira": preload("res://assets/utensilios/frigideira_full.png")
}

# ---------------------------
# Attach / Initialize
# ---------------------------
func attach_to_anchor(node: Control) -> void:
	global_position = node.global_position

func initialize(t_type: String, ingredients: Array[Dictionary]) -> void:
	tool_type = t_type
	ingredient_data_list = ingredients.duplicate(true)
	await get_tree().process_frame
	if tool_type != "":
		var base_path := "res://assets/utensilios/%s.png" % tool_type
		if ResourceLoader.exists(base_path):
			tool_sprite.texture = load(base_path)
	_setup_visuals()

func _ready() -> void:
	if background:
		background.visible = show_background

	await get_tree().process_frame

	var rot := int(round(heat_bar.rotation_degrees)) % 360
	var ar = abs(rot)
	_use_vertical_axis = not (ar == 90 or ar == 270)

	if _use_vertical_axis:
		marker_range = heat_bar.size.y - heat_marker.size.y
		heat_marker.position.y = marker_range
	else:
		marker_range = heat_bar.size.x - heat_marker.size.x
		heat_marker.position.x = 0.0

	set_process(true)
	# não usamos gui_input/signals — processamento de clique via _input

# ---------------------------
# Visual setup
# ---------------------------
func _setup_visuals() -> void:
	# desliga tudo
	if pan_anim:
		pan_anim.visible = false
		pan_anim.stop()
	if fry_anim:
		fry_anim.visible = false
		fry_anim.stop()

	tool_sprite.visible = true

	# ativa conforme ferramenta
	if tool_type == "panela":
		tool_sprite.visible = false
		if pan_anim:
			pan_anim.visible = true
			pan_anim.frame = 0
			pan_anim.play("boil")
		if pan_area:
			pan_area.visible = true
		if fry_area:
			fry_area.visible = false
	elif tool_type == "frigideira":
		tool_sprite.visible = false
		if fry_anim:
			fry_anim.visible = true
			fry_anim.frame = 0
			fry_anim.play("fry")
		if fry_area:
			fry_area.visible = true
		if pan_area:
			pan_area.visible = false
	else:
		# default: nada animado
		if pan_area:
			pan_area.visible = false
		if fry_area:
			fry_area.visible = false

	_refresh_mini_icons()

# ---------------------------
# Mini icons
# ---------------------------
func _refresh_mini_icons() -> void:
	for c in mini_icons.get_children():
		c.queue_free()
	for ing in ingredient_data_list:
		var tex: Texture2D = null
		if Managers and Managers.ingredient_database:
			tex = Managers.ingredient_database.get_mini_icon(ing.get("id", ""), ing.get("state", ""))
		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			mini_icons.add_child(icon)

# ---------------------------
# Process (marker)
# ---------------------------
func _process(delta: float) -> void:
	if not is_cooking:
		return

	if _use_vertical_axis:
		heat_marker.position.y = max(0.0, heat_marker.position.y - cook_speed * delta)
		if heat_marker.position.y <= 0.0:
			_stop_and_evaluate()
	else:
		heat_marker.position.x = min(marker_range, heat_marker.position.x + cook_speed * delta)
		if heat_marker.position.x >= marker_range:
			_stop_and_evaluate()

# ---------------------------
# Input global: checa clique e testa colisões manualmente
# ---------------------------
func _input(event: InputEvent) -> void:
	if not is_cooking:
		return
	if event is InputEventMouseButton and event.pressed:
		var global_click := get_viewport().get_mouse_position()
		# 1) clique sobre heat_bar?
		if _point_in_control_global(heat_bar, global_click):
			_stop_and_evaluate()
			return
		# 2) clique sobre pan_area?
		if pan_area and pan_area.is_inside_tree() and pan_area.visible:
			if _point_in_area_collision(pan_area, global_click):
				_stop_and_evaluate()
				return
		# 3) clique sobre fry_area?
		if fry_area and fry_area.is_inside_tree() and fry_area.visible:
			if _point_in_area_collision(fry_area, global_click):
				_stop_and_evaluate()
				return
		# 4) clique diretamente sobre tool_sprite?
		if _point_in_control_global(tool_sprite, global_click) and tool_sprite.visible:
			_stop_and_evaluate()
			return

func _stop_and_evaluate() -> void:
	is_cooking = false
	AudioManager.stop_loop_sfx()
	_evaluate_cook()

# ---------------------------
# Helpers: Control pick
# ---------------------------
func _point_in_control_global(c: Control, global_point: Vector2) -> bool:
	if c == null or not c.is_inside_tree():
		return false
	# Control's global_position + size (works mesmo se ancorado)
	var tl := c.get_global_position()
	var rect := Rect2(tl, c.size)
	return rect.has_point(global_point)

# ---------------------------
# Helpers: test point vs CollisionShape2D via to_local
# ---------------------------
func _point_in_area_collision(a: Area2D, global_point: Vector2) -> bool:
	if a == null or not a.is_inside_tree():
		return false
	var shape_node := a.get_node_or_null("CollisionShape2D")
	if shape_node == null:
		# fallback: distância ao centro do Area2D
		return a.get_global_position().distance_to(global_point) < 48.0
	var shape = shape_node.shape
	if shape == null:
		return false

	# converte ponto global para local do CollisionShape2D (usamos to_local do Node2D)
	var p_local = shape_node.to_local(global_point)

	# RectangleShape2D: comparar com extents
	if shape is RectangleShape2D:
		var ext := (shape as RectangleShape2D).size * 0.5
		var rect := Rect2(-ext, ext * 2)
		return rect.has_point(p_local)

	# CircleShape2D: comparar raio
	if shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		return p_local.length() <= r

	# Capsule/Convex/others: fallback para distância ao centro do CollisionShape2D
	return (p_local.length() <= 48.0)

# ---------------------------
# Evaluate cook
# ---------------------------
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
		var pos := heat_marker.position.x
		var cool_end := zone_cool.position.x + zone_cool.size.x
		var ideal_start := zone_ideal.position.x
		var ideal_end := ideal_start + zone_ideal.size.x
		var burn_start := zone_burn.position.x

		if pos >= ideal_start and pos <= ideal_end:
			result_label = "✅ No ponto!"
		elif pos < cool_end:
			result_label = "🧊 Cru"
		elif pos > burn_start:
			result_label = "🔥 Queimado"
		else:
			result_label = "😐 Mais ou menos"

	_show_result(result_label)

# ---------------------------
# Show result
# ---------------------------
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

func _label_to_quality(label: String) -> String:
	match label:
		"✅ No ponto!": return "perfect"
		"🔥 Queimado", "❌ Queimado!": return "burnt"
		"🧊 Cru": return "raw"
		"😐 Mais ou menos": return "meh"
		_: return "unknown"
