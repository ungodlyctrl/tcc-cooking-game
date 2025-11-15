# res://scenes/minigames/cutting_board_qte.gd
extends Control
class_name CuttingBoardQTE

signal finished_cut(ingredient_id: String, hits: int)

# ---------------- Consts / Defaults ----------------
const KNIFE_OFFSET_Y: float = -15.0

# ---------------- Exports / Config ----------------
@export var ingredient_name: String = ""
# Opcional: se não passar difficulty_preset, o script tentará usar board_area to pick one.
@export var difficulty_preset: Resource = null  # CuttingDifficultyResource

# ---------------- Estado ----------------
var board_area: Node = null
var _attempts_left: int = 0
var _score: int = 0
var _hit_registered: bool = false
var _pointer_dir: int = 1   # 1 = direita, -1 = esquerda
var _pointer_active: bool = true

# ---------------- Onready ----------------
@onready var ingredient_sprite: TextureRect = $IngredientSprite
@onready var qte_bar: Control = $QTEBar
@onready var pointer: TextureRect = $QTEBar/Pointer
@onready var zones_parent: Control = $QTEBar/Hitzones
@onready var knife: TextureRect = $CanvasLayer/Knife2
@onready var feedback: Label = $FeedbackLabel

# runtime params (populados por preset)
var _pointer_speed: float = 120.0
var _attempts_init: int = 3
var _hitzone_positions: Array = []
var _hitzone_sizes: Array = []
var _hitzone_nodes: Array = []
var _hitzone_base_mod: Color = Color(0.803, 0.820, 0.835, 0.45)
var _hitzone_hit_mod: Color = Color(0.49, 0.878, 0.506, 0.55)
var _pointer_bounce: bool = true
var _pointer_auto_end_on_return: bool = true

# ---------------- READY ----------------
func _ready() -> void:
	# carregar sprite do ingrediente
	var tex: Texture2D = Managers.ingredient_database.get_sprite(ingredient_name, "raw")
	if tex:
		ingredient_sprite.texture = tex
	else:
		push_error("❌ Sprite não encontrado para: %s (raw)" % ingredient_name)

	# knife visuals
	knife.visible = false
	knife.modulate.a = 0.0

	# carregar preset: prefer difficulty_preset, senão tentar obter via board_area
	_load_preset()

	# setup pointer / zones
	_setup_hitzones()
	pointer.position.x = 0
	_pointer_dir = 1
	_hit_registered = false
	_pointer_active = true
	_score = 0
	_attempts_left = _attempts_init
	feedback.text = ""
	set_process(true)

# ---------------- PRESET LOADER ----------------
func _load_preset() -> void:
	# prioridade: explicit preset
	if difficulty_preset != null:
		_apply_preset(difficulty_preset)
		return

	# se board_area definido e tem cutting_difficulties, tentar escolher por day
	if board_area != null and board_area.has_method("get_cutting_difficulties"):
		var arr : Array = board_area.get_cutting_difficulties()
		if arr and arr.size() > 0:
			# tenta obter dia atual do MainScene (se existir)
			var day := 1
			var ms := get_tree().current_scene
			if ms and ms.has_method("get"):
				var maybe_day = ms.get("day")
				if typeof(maybe_day) == TYPE_INT:
					day = maybe_day


			# seleciona melhor preset (maior min_day <= day)
			var best = null
			for p in arr:
				if p is CuttingDifficultyResource:
					# resource object (CuttingDifficultyResource)
					if p.min_day <= day:
						if best == null or p.min_day > best.min_day:
							best = p
			if best != null:
				_apply_preset(best)
				return

	# fallback default
	_apply_preset(null)


func _apply_preset(preset: Resource) -> void:
	if preset == null:
		# valores default
		_pointer_speed = 120.0
		_attempts_init = 3
		_hitzone_positions = [0.2, 0.45, 0.7]
		_hitzone_sizes = [0.12, 0.12, 0.12]
		_hitzone_base_mod = Color(0.803, 0.820, 0.835, 0.45)
		_hitzone_hit_mod = Color(0.49, 0.878, 0.506, 0.55)
		_pointer_bounce = true
		_pointer_auto_end_on_return = true
		return

	# assume CuttingDifficultyResource shape
	_pointer_speed = float(preset.pointer_speed)
	_attempts_init = int(preset.attempts)
	_hitzone_positions = preset.hitzone_positions.duplicate(true)
	_hitzone_sizes = preset.hitzone_sizes.duplicate(true)
	_hitzone_base_mod = preset.hitzone_base_modulate
	_hitzone_hit_mod = preset.hitzone_hit_modulate
	_pointer_bounce = bool(preset.pointer_bounce)
	_pointer_auto_end_on_return = bool(preset.pointer_auto_end_on_return)


# ---------------- Hitzones setup ----------------
func _setup_hitzones() -> void:
	# limpa hitzones existentes
	for hn in _hitzone_nodes:
		if hn and hn.is_inside_tree():
			hn.queue_free()
	_hitzone_nodes.clear()

	# sanity checks
	var count = max(_hitzone_positions.size(), _hitzone_sizes.size())
	if count == 0:
		return

	var bar_w := qte_bar.size.x

	for i in range(count):
		var pos_norm := 0.0
		var size_norm := 0.05
		if i < _hitzone_positions.size():
			pos_norm = float(_hitzone_positions[i])
		if i < _hitzone_sizes.size():
			size_norm = float(_hitzone_sizes[i])

		var hnode := ColorRect.new()
		hnode.name = "Hitzone_%d" % i
		hnode.anchor_left = 0
		hnode.anchor_top = 0
		hnode.anchor_right = 0
		hnode.anchor_bottom = 0
		hnode.position = Vector2(bar_w * pos_norm - (bar_w * size_norm) / 2.0, 0)
		hnode.custom_minimum_size = Vector2(bar_w * size_norm, qte_bar.size.y)
		hnode.color = _hitzone_base_mod
		hnode.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zones_parent.add_child(hnode)
		_hitzone_nodes.append(hnode)


# ---------------- PROCESS / POINTER ----------------
func _process(delta: float) -> void:
	if not _pointer_active:
		return
	if _hit_registered:
		return

	var bar_w := qte_bar.size.x
	var p_w := pointer.size.x

	# update pointer
	var dx := _pointer_speed * _pointer_dir * delta
	pointer.position.x = clamp(pointer.position.x + dx, 0, bar_w - p_w)

	# se chegou na borda direita
	if _pointer_dir == 1 and pointer.position.x >= bar_w - p_w - 0.001:
		if _pointer_bounce:
			_pointer_dir = -1
		else:
			# fim
			_on_pointer_reached_end()

	# se voltou ao começo (esquerda) e auto_end está activado
	if _pointer_dir == -1 and pointer.position.x <= 0 + 0.001:
		if _pointer_auto_end_on_return:
			_on_pointer_reached_return()
		else:
			# inverte novamente (opcional)
			_pointer_dir = 1


# ---------------- INPUT / TENTATIVA ----------------
func _input(event: InputEvent) -> void:
	if not is_cooking():
		return
	if event is InputEventMouseButton and event.pressed:
		_attempt_cut()


func is_cooking() -> bool:
	return not _hit_registered and _attempts_left > 0


func _attempt_cut() -> void:
	_attempts_left -= 1
	var pointer_x := pointer.position.x
	var success := false

	# calcula zona de hit nos nós de hitzone reais (em pixels)
	for hn in _hitzone_nodes:
		var start_x = hn.position.x
		var end_x = start_x + hn.size.x
		if pointer_x >= start_x and pointer_x <= end_x:
			success = true
			hn.color = _hitzone_hit_mod
			_score += 1
			break

	if success:
		feedback.text = "Corte bom!"
	else:
		feedback.text = "Fora da zona"

	# anima faca e som (se quiser adicionar)
	_show_knife_effect()

	if _attempts_left <= 0:
		# esperar um pouco e encerrar
		await get_tree().create_timer(0.08).timeout
		end_qte()


# ---------------- KNIFE EFFECT ----------------
func _show_knife_effect() -> void:
	var section_index = clamp(3 - _attempts_left, 0, max(0, _hitzone_nodes.size()-1))
	var ingredient_pos := ingredient_sprite.get_global_position()
	# posiciona knife sobre o ingrediente (aprox)
	var knife_start := Vector2(
		ingredient_pos.x + ingredient_sprite.size.x * (section_index / max(1, float(max(1, _hitzone_nodes.size())))),
		ingredient_pos.y + KNIFE_OFFSET_Y
	)

	knife.visible = true
	knife.modulate.a = 1.0
	knife.position = knife_start
	knife.z_index = 100

	var tween := create_tween()
	tween.tween_property(knife, "position", knife_start + Vector2(6, 6), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(knife, "modulate:a", 0.0, 0.08).set_delay(0.08)
	await tween.finished
	knife.visible = false


# ---------------- POINTER END HANDLERS ----------------
func _on_pointer_reached_end() -> void:
	# se não tem bounce, encerra
	end_qte()

func _on_pointer_reached_return() -> void:
	# se auto_end_on_return true -> encerra
	end_qte()


# ---------------- FIM DO QTE ----------------
func end_qte() -> void:
	_pointer_active = false
	set_process(false)
	_hit_registered = true

	var max_hits = max(1, _hitzone_nodes.size())
	var ratio := float(_score) / float(max_hits)

	if ratio >= 0.90:
		feedback.text = "Perfeito!"
	elif ratio >= 0.70:
		feedback.text = "Bom!"
	elif ratio >= 0.40:
		feedback.text = "Razoável"
	else:
		feedback.text = "Ruim"

	await get_tree().create_timer(0.8).timeout

	_spawn_cut_ingredient()
	emit_signal("finished_cut", ingredient_name, _score)

	if board_area != null and board_area.is_inside_tree():
		var bancada_knife := board_area.get_node_or_null("BancadaKnife")
		if bancada_knife:
			bancada_knife.visible = true

	queue_free()



# ---------------- SPAWN DO INGREDIENTE CORTADO ----------------
func _spawn_cut_ingredient() -> void:
	var ingredient_scene := preload("res://scenes/ui/ingredient.tscn")
	var ingredient := ingredient_scene.instantiate()
	ingredient.ingredient_id = ingredient_name
	ingredient.state = "cut"
	ingredient.is_cutting_result = true
	ingredient.set_meta("qte_hits", _score)

	if board_area != null and board_area.is_inside_tree():
		# adiciona como filho da board_area (local)
		board_area.add_child(ingredient)
		var board_size = board_area.size
		var ing_size = ingredient.size
		ingredient.position = (board_size / 2.0) - (ing_size / 2.0)

		# notifica board_area que temos resultado
		if board_area.has_method("notify_result_placed"):
			board_area.notify_result_placed(ingredient)

		# quando o ingrediente sair da cena (arrastado e entregue/removed), avisa o board
		ingredient.tree_exited.connect(func():
			if board_area and board_area.is_inside_tree():
				if board_area.has_method("notify_ingredient_removed"):
					board_area.notify_ingredient_removed())
	else:
		push_warning("CuttingBoardQTE: board_area indisponível para adicionar o resultado.")
