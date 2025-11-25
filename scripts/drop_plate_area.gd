extends Control
class_name DropPlateArea

signal drag_state_changed(is_dragging: bool)

# --- Consts
const PLATE_SPRITE_SIZE: Vector2 = Vector2(96, 96)
const PLATE_DRAG_OFFSET: Vector2 = Vector2(-40, -30)

# --- Nodes
@onready var plate_root: Control = $PlateRoot
@onready var base_plate: TextureRect = $PlateRoot/BasePlate
@onready var visual_container: Control = $PlateRoot/VisualContainer
@onready var used_list: VBoxContainer = $VBoxContainer/UsedList
@onready var mini_icons: HBoxContainer = $MiniIconsContainer

# --- Estado
var used_ingredients: Array[Dictionary] = []
var expected_recipe: RecipeResource = null
var _visual_nodes: Array[Control] = []
var _ready_finished: bool = false
var _is_dragging_local: bool = false
var _saved_base_texture: Texture2D = null

# ---------------- READY ----------------
func _ready() -> void:
	await get_tree().process_frame
	_ready_finished = true

	if typeof(DragManager) != TYPE_NIL:
		DragManager.current_drag_type = DragManager.DragType.NONE

	if expected_recipe:
		_update_plate_visuals()

	gui_input.connect(_on_gui_input)



# ---------------- GUI INPUT ----------------
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not used_ingredients.is_empty() or _is_recipe_fulfilled():
				if typeof(DragManager) != TYPE_NIL:
					DragManager.current_drag_type = DragManager.DragType.PLATE
		else:
			if typeof(DragManager) != TYPE_NIL:
				DragManager.current_drag_type = DragManager.DragType.NONE



# ---------------- VISIBILIDADE ----------------
func _set_plate_root_visible(visible: bool) -> void:
	if plate_root and plate_root.is_inside_tree():
		plate_root.visible = visible
	used_list.visible = not (visual_container.get_child_count() > 0)



# ---------------- CONFIGURAÇÃO ----------------
func set_current_recipe(recipe: RecipeResource) -> void:
	if not is_instance_valid(self):
		return

	expected_recipe = recipe
	clear_ingredients()
	_update_mini_icons()

	if expected_recipe:
		print("✅ DropPlateArea recebeu receita:", expected_recipe.recipe_name)
	else:
		print("⚠️ DropPlateArea recebeu receita nula.")

	_ready_finished = true
	_update_plate_visuals()



func clear_ingredients() -> void:
	used_ingredients.clear()

	for n in _visual_nodes:
		if n and n.is_inside_tree():
			n.queue_free()
	_visual_nodes.clear()

	for c in used_list.get_children():
		c.queue_free()

	for c in mini_icons.get_children():
		c.queue_free()


# ---------------- ADD INGREDIENTS ----------------
func add_ingredients(ingredients: Array[Dictionary]) -> void:
	if expected_recipe == null:
		_try_recover_recipe()
		if expected_recipe == null:
			push_warning("❌ Nenhuma receita disponível — ignorando ingredientes.")
			return

	for ing in ingredients:
		used_ingredients.append(ing)

	_update_ingredient_list_ui()
	_update_plate_visuals()
	_update_mini_icons()


func _try_recover_recipe() -> void:
	var ms := get_tree().current_scene

	if ms != null and ms.has_method("get"):
		var maybe = ms.get("current_recipe")
		if maybe:
			expected_recipe = maybe
			print("♻️ Receita recuperada automaticamente do MainScene:", expected_recipe.recipe_name)
			return

	if Managers != null and Managers.has_method("get_current_recipe"):
		var mr = Managers.get_current_recipe()
		if mr:
			expected_recipe = mr
			print("♻️ Receita recuperada automaticamente do Managers.")
			return

	print("⚠️ _try_recover_recipe(): não foi possível recuperar recipe automaticamente.")



# ---------------- BUSCA DE SPRITES ----------------
func _get_plate_sprite_for(id: String, state: String, quantity: int = 1) -> Texture2D:
	var id_lower := id.to_lower()
	var st_lower := state.to_lower()

	# ============================================================
	# 1) TENTA SPRITE ESPECÍFICO DA RECEITA
	# ============================================================
	if expected_recipe and expected_recipe.plate_ingredient_visuals:
		for vis in expected_recipe.plate_ingredient_visuals:
			if vis and vis.ingredient_id.to_lower() == id_lower:

				# tenta match perfeito de state/quantidade
				for entry in vis.state_sprites:
					if entry == null or entry.texture == null:
						continue

					var entry_state := entry.state.to_lower()

					# variantes tipo "cooked_2", "raw_3"…
					if entry_state == "%s_%d" % [st_lower, quantity]:
						return entry.texture

					# variantes tipo "qty2", "count2"
					if entry_state == "qty%d" % quantity:
						return entry.texture
					if entry_state == "count%d" % quantity:
						return entry.texture

					# match direto de state ("raw", "cut", "cooked")
					if entry_state == st_lower:
						return entry.texture

				# se nenhum entry bateu, tenta default
				for entry in vis.state_sprites:
					if entry and entry.state.to_lower() in ["", "default"]:
						return entry.texture

	# ============================================================
	# 2) FALLBACK UNIVERSAL → SEMPRE TENTAR "plate" PRIMEIRO
	# ============================================================
	if Managers and Managers.ingredient_database:
		var tex_plate := Managers.ingredient_database.get_sprite(id, "plate")
		if tex_plate:
			return tex_plate

	# ============================================================
	# 3) FALLBACK NORMAL → procurar qualquer outro state
	#    (ordem sugerida: raw → cooked → cut → fried)
	# ============================================================
	if Managers and Managers.ingredient_database:
		var order := ["raw", "cooked", "cut", "fried"]

		for s in order:
			var tex := Managers.ingredient_database.get_sprite(id, s)
			if tex:
				return tex

	# ============================================================
	# 4) nada encontrado
	# ============================================================
	return null






#----------------- ICONES -----------
func _update_mini_icons() -> void:
	# limpa
	for c in mini_icons.get_children():
		c.queue_free()

	# recria
	for ing in used_ingredients:
		var id : String = ing.get("id", "")
		var st : String = ing.get("state", "")

		var tex := Managers.ingredient_database.get_mini_icon(id, st)
		if tex == null:
			continue

		var icon := TextureRect.new()
		icon.texture = tex
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# erro? pinta vermelho
		if not _ingredient_is_expected(ing):
			icon.modulate = Color("ff8080ff")

		mini_icons.add_child(icon)


# ---------------- VISUAIS ----------------
func _update_plate_visuals() -> void:
	if expected_recipe == null:
		return

	for n in _visual_nodes:
		if n and n.is_inside_tree():
			n.queue_free()

	_visual_nodes.clear()

	var has_sprites: bool = false

	if _is_recipe_fulfilled() and expected_recipe.final_plate_sprite:
		var spr := TextureRect.new()
		spr.texture = expected_recipe.final_plate_sprite
		spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		spr.custom_minimum_size = PLATE_SPRITE_SIZE
		spr.size = PLATE_SPRITE_SIZE
		spr.position = await _center_visual_position_for(spr)

		visual_container.add_child(spr)
		_visual_nodes.append(spr)
		has_sprites = true

	else:
		var qty_map: Dictionary = {}

		for ing in used_ingredients:
			var key := "%s|%s" % [ing["id"], ing["state"]]
			qty_map[key] = qty_map.get(key, 0) + 1

		for key in qty_map.keys():
			var parts: PackedStringArray = key.split("|")
			var id: String = parts[0]
			var st: String = parts[1]
			var count: int = qty_map[key]

			var tex := _get_plate_sprite_for(id, st, count)
			if tex == null:
				continue

			var node := TextureRect.new()
			node.texture = tex
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			node.custom_minimum_size = PLATE_SPRITE_SIZE
			node.size = PLATE_SPRITE_SIZE
			node.position = await _center_visual_position_for(node) + _get_offset_for(id)
			node.z_index = _get_z_for(id, 0)

			visual_container.add_child(node)
			_visual_nodes.append(node)
			has_sprites = true

	used_list.visible = not has_sprites



# ---------------- CENTRALIZAÇÃO ----------------
func _center_visual_position_for(node: Control) -> Vector2:
	await get_tree().process_frame

	var vc_size: Vector2 = visual_container.size
	if vc_size == Vector2.ZERO:
		vc_size = visual_container.get_combined_minimum_size()
		if vc_size == Vector2.ZERO:
			vc_size = plate_root.size

	var node_size: Vector2 = node.custom_minimum_size
	if node_size == Vector2.ZERO:
		node_size = PLATE_SPRITE_SIZE

	return (vc_size - node_size) / 2.0



# ---------------- OFFSET / Z ----------------
func _get_offset_for(id: String) -> Vector2:
	if expected_recipe and expected_recipe.plate_ingredient_visuals:
		for vis in expected_recipe.plate_ingredient_visuals:
			if vis and vis.ingredient_id == id:
				return vis.offset
	return Vector2.ZERO


func _get_z_for(id: String, idx: int) -> int:
	if expected_recipe and expected_recipe.plate_ingredient_visuals:
		for vis in expected_recipe.plate_ingredient_visuals:
			if vis and vis.ingredient_id == id:
				return vis.z_index + idx
	return idx



# ---------------- CHECAGEM RECEITA COMPLETA ----------------
func _is_recipe_fulfilled() -> bool:
	if expected_recipe == null:
		return false

	var need: Dictionary = {}
	for req in expected_recipe.ingredient_requirements:
		if req == null:
			continue
		var key := "%s|%s" % [req.ingredient_id, req.state]
		need[key] = need.get(key, 0) + int(req.quantity)

	var have: Dictionary = {}
	for ing in used_ingredients:
		var key := "%s|%s" % [ing.get("id", ""), ing.get("state", "")]
		have[key] = have.get(key, 0) + 1

	for key in need.keys():
		if have.get(key, 0) < need[key]:
			return false

	return true



# ---------------- DRAG & DROP ----------------
func _get_drag_data(_pos: Vector2) -> Variant:
	if used_ingredients.is_empty() and not _is_recipe_fulfilled():
		return null

	var preview := Control.new()
	preview.name = "drag_preview_plate"
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = PLATE_SPRITE_SIZE
	preview.size = PLATE_SPRITE_SIZE

	if base_plate and base_plate.texture:
		var plate_sprite := TextureRect.new()
		plate_sprite.texture = base_plate.texture
		plate_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plate_sprite.custom_minimum_size = PLATE_SPRITE_SIZE
		plate_sprite.size = PLATE_SPRITE_SIZE
		plate_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.add_child(plate_sprite)

	var container_center: Vector2 = (visual_container.size - PLATE_SPRITE_SIZE) / 2.0

	for node in _visual_nodes:
		if node and node.texture:
			var clone := TextureRect.new()
			clone.texture = node.texture
			clone.stretch_mode = node.stretch_mode
			clone.custom_minimum_size = node.size
			clone.size = node.size
			clone.position = node.position - container_center
			clone.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview.add_child(clone)

	preview.position = PLATE_DRAG_OFFSET
	set_drag_preview(preview)

	call_deferred("_hide_plateroot_for_drag")

	if typeof(DragManager) != TYPE_NIL:
		DragManager.current_drag_type = DragManager.DragType.PLATE

	return {
		"type": "plate",
		"ingredients": used_ingredients.duplicate(true),
		"source": self
	}



func _hide_plateroot_for_drag() -> void:
	_is_dragging_local = true

	if base_plate and base_plate.texture:
		_saved_base_texture = base_plate.texture

	_set_plate_root_visible(false)
	await get_tree().process_frame
	emit_signal("drag_state_changed", true)



# ---------------- DROP ----------------
func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false

	# BLOQUEIA ferramentas (panela/frigideira) e cooked_tool
	if data.get("state", "") == "tool":
		return false

	# Só aceita:
	# 1) cooked_tool
	# 2) ingredientes individuais
	if data.has("type") and data["type"] == "cooked_tool":
		return true

	if data.has("id") and data.has("state"):
		return true

	return false




func _drop_data(_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_position, data):
		return

	var ingredients_to_add: Array[Dictionary] = []

	# ------------------------------
	# COOKED TOOL → adiciona ingredientes
	# ------------------------------
	if data.has("type") and data["type"] == "cooked_tool":
		if data.has("ingredients"):
			ingredients_to_add = data["ingredients"]

		var src = data.get("source", null)
		if src and src.is_inside_tree():
			src.queue_free()

	# ------------------------------
	# INGREDIENTE (cru OU cortado)
	# ------------------------------
	elif data.has("id") and data.has("state"):
		ingredients_to_add.append({
			"id": data["id"],
			"state": data["state"]
		})

		var src = data.get("source", null)
		if src and src.is_inside_tree():
			src.queue_free()

	add_ingredients(ingredients_to_add)





# ---------------- RESTAURAÇÃO ----------------
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if _is_dragging_local:
			_is_dragging_local = false
			_set_plate_root_visible(true)
			emit_signal("drag_state_changed", false)

# Garantir fim do drag, independente de qualquer coisa
		if typeof(DragManager) != TYPE_NIL:
			DragManager.current_drag_type = DragManager.DragType.NONE

			emit_signal("drag_state_changed", false)




# ---------------- VISUAL DE ERRO ----------------
func _flash_wrong_ing_visual(ing: Dictionary) -> void:
	var id: String = ing.get("id", "")
	var st: String = ing.get("state", "")
	var tex := _get_plate_sprite_for(id, st)

	if tex == null:
		return

	var node := TextureRect.new()
	node.texture = tex
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.modulate = Color(1, 0.4, 0.4)
	node.position = await _center_visual_position_for(node)

	visual_container.add_child(node)

	await get_tree().create_timer(0.25).timeout

	if node.is_inside_tree():
		node.queue_free()



# ---------------- LISTAGEM TEXTUAL ----------------
func _update_ingredient_list_ui() -> void:
	for c in used_list.get_children():
		c.queue_free()

	var count_map: Dictionary = {}

	for ing in used_ingredients:
		var key := "%s|%s" % [ing["id"], ing["state"]]
		count_map[key] = count_map.get(key, 0) + 1

	for key in count_map.keys():
		var parts: PackedStringArray = key.split("|")
		var id: String = parts[0]
		var state: String = parts[1]
		var amount: int = count_map[key]

		var label := Label.new()
		label.text = "- %s (%s) x%d" % [id.capitalize(), state, amount]
		used_list.add_child(label)

	used_list.visible = _visual_nodes.is_empty()



# ---------------- UTIL ----------------
func _ingredient_is_expected(ing: Dictionary) -> bool:
	if expected_recipe == null:
		return true

	for req in expected_recipe.ingredient_requirements:
		if req and req.ingredient_id == ing.get("id", ""):
			return true

	return false
