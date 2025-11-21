extends Control
class_name CookingMinigame

signal finished(result_ingredients: Array[Dictionary], tool_type: String, quality: String)

# --------------------------------
# CONSTANTES
# --------------------------------
const STATE_FRIED := "fried"
const STATE_COOKED := "cooked"

# --------------------------------
# EXPORTS / SETTINGS
# --------------------------------
@export var tool_type: String = ""
@export var cook_speed: float = 50.0
@export var show_background: bool = false

# --------------------------------
# NODES
# --------------------------------
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

# --------------------------------
# STATE VARS
# --------------------------------
var ingredient_data_list: Array[Dictionary] = []
var is_cooking := true
var marker_range := 0.0
var result_label := ""
var anchor: Control = null

# true = usamos Y (vertical: marker sobe de bottom → top)
# false = usamos X (rotated bar: marker se move left→right)
var _use_vertical_axis := true

# --------------------------------
# PRELOADS DE TEXTURAS FINAIS
# --------------------------------
var full_pan_textures := {
	"panela": preload("res://assets/utensilios/panela_full.png"),
	"frigideira": preload("res://assets/utensilios/frigideira_full.png")
}

# --------------------------------
# SETUP
# --------------------------------
func attach_to_anchor(node: Control) -> void:
	anchor = node
	global_position = anchor.global_position

func initialize(t_type: String, ingredients: Array[Dictionary]) -> void:
	tool_type = t_type
	ingredient_data_list = ingredients.duplicate(true)

	# Só aqui chamamos o setup
	await get_tree().process_frame # garante carregamento de animação
	_setup_visuals()


func _ready() -> void:
	if background:
		background.visible = show_background


	# Decide qual eixo usar a partir da rotação do heat_bar
	var rot := int(round(heat_bar.rotation_degrees)) % 360
	var absrot = abs(rot)
	# consider 90° ou 270° como "barra rotacionada"
	if absrot == 90 or absrot == 270:
		_use_vertical_axis = false
	else:
		_use_vertical_axis = true

	# espera frame para garantir tamanhos válidos no editor
	await get_tree().process_frame

	if _use_vertical_axis:
		marker_range = heat_bar.size.y - heat_marker.size.y
		# inicio na posição de baixo (máximo y)
		heat_marker.position.y = marker_range
	else:
		# horizontal motion (x)
		marker_range = heat_bar.size.x - heat_marker.size.x
		# inicio à esquerda (x = 0) ou à direita?
		# definimos: marker sobe de left -> right so start at 0
		heat_marker.position.x = 0.0

	set_process(true)

	# clique ampliado — qualquer clique no Minigame conta
	gui_input.connect(_on_any_click_stop)
	# também no sprite/anim para garantir clique em todas as áreas
	if tool_sprite:
		tool_sprite.gui_input.connect(_on_any_click_stop)
	if pan_anim:
		pan_anim.gui_input.connect(_on_any_click_stop)


# --------------------------------
# VISUAL SETUP
# --------------------------------
func _setup_visuals() -> void:
	# ---------------------------------------------------------
	# PANELA → usar animação
	# FRIGIDEIRA → esconder completamente o PanAnim
	# ---------------------------------------------------------
	if pan_anim:
		if tool_type == "panela":
			pan_anim.visible = true
			# força reset da animação
			pan_anim.stop()
			pan_anim.frame = 0

			# garante animação válida
			var anims = pan_anim.frames.get_animation_names()
			if anims.has("boil"):
				pan_anim.animation = "boil"
			elif anims.size() > 0:
				pan_anim.animation = anims[0]

			# IMPORTANTE: esperar um frame antes de dar play
			await get_tree().process_frame
			pan_anim.play()
		else:
			# FRIGIDEIRA → esconder
			pan_anim.visible = false
			pan_anim.stop()

	# ---------------------------------------------------------
	# TOOL SPRITE:
	# panela → escondido (porque a animação fica no lugar)
	# frigideira → mantem visible (não existe animação dela)
	# ---------------------------------------------------------
	if tool_sprite:
		if tool_type == "panela":
			tool_sprite.visible = false
		else:
			tool_sprite.visible = true

	tool_sprite.z_index = 50

	# ---------------------------------------------------------
	# MINI ICONS (natural size)
	# ---------------------------------------------------------
	_refresh_mini_icons()






func _refresh_mini_icons() -> void:
	# limpa filhos existentes
	for child in mini_icons.get_children():
		if child and child.is_inside_tree():
			child.queue_free()

	# recria
	for ing in ingredient_data_list:
		var id = ing.get("id", "")
		var st = ing.get("state", "")
		var tex = null
		if Managers and Managers.ingredient_database:
			tex = Managers.ingredient_database.get_mini_icon(id, st)
		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			# NÃO forçamos size — deixa o ícone no tamanho natural
			icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mini_icons.add_child(icon)


# --------------------------------
# PROCESSO (movimento do marker)
# --------------------------------
func _process(delta: float) -> void:
	if not is_cooking:
		return

	if _use_vertical_axis:
		# mover marker de baixo pra cima: reduz y até 0
		var new_y := heat_marker.position.y - cook_speed * delta
		heat_marker.position.y = max(0.0, new_y)

		# chegou ao topo -> queimou
		if heat_marker.position.y <= 0.0:
			is_cooking = false
			_show_result("❌ Queimado!")
	else:
		# mover marker no eixo X (left -> right)
		var new_x := heat_marker.position.x + cook_speed * delta
		heat_marker.position.x = min(marker_range, new_x)

		# chegou ao final -> queimou
		if heat_marker.position.x >= marker_range:
			is_cooking = false
			_show_result("❌ Queimado!")


# --------------------------------
# CLIQUES PARA PARAR
# --------------------------------
func _on_any_click_stop(event: InputEvent) -> void:
	if not is_cooking:
		return
	if event is InputEventMouseButton and event.pressed:
		is_cooking = false
		_evaluate_cook()


# --------------------------------
# AVALIAÇÃO (usa o eixo correto)
# --------------------------------
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
		# eixo X
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


# --------------------------------
# RESULTADO FINAL
# --------------------------------
func _show_result(text: String) -> void:
	if feedback:
		feedback.text = text

	# parar animação da panela
	if pan_anim:
		pan_anim.stop()
		pan_anim.visible = false

	# mostrar textura final da panela cheia (se houver)
	if tool_sprite:
		var full_tex = full_pan_textures.get(tool_type, null)
		if full_tex:
			tool_sprite.texture = full_tex
		tool_sprite.visible = true

	# espera um pouco e emite resultado
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
