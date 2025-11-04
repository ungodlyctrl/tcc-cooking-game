extends TextureRect
class_name DropPlateArea

## Área onde o jogador monta o prato com sprites modulares.
## Mostra sprites específicos definidos na receita (RecipeResource.plate_ingredient_visuals)
## e, se faltar algo, usa fallback da IngredientDatabase.
## Agora o prato pode ser arrastado com preview visual e muda os sprites conforme a quantidade.

@onready var used_list: VBoxContainer = $VBoxContainer/UsedList
@onready var visual_container: Control = $VisualContainer

const PLATE_SPRITE_SIZE := Vector2(96, 96)
const PLATE_DRAG_OFFSET := Vector2(-40, -30)

var used_ingredients: Array[Dictionary] = []
var expected_recipe: RecipeResource = null
var _visual_nodes: Array[Control] = []
var _ready_finished: bool = false


# ---------------------- READY ----------------------
func _ready() -> void:
	await get_tree().process_frame
	_ready_finished = true
	print("🟢 DropPlateArea pronto.")
	
	# 🔧 Garante reset de estado de drag ao iniciar
	if typeof(DragManager) != TYPE_NIL:
		DragManager.current_drag_type = DragManager.DragType.NONE

	if expected_recipe:
		print("🔁 Receita já estava setada:", expected_recipe.recipe_name)
		_update_plate_visuals()
	else:
		print("🔁 Nenhuma receita atribuída ainda no DropPlateArea.")

	# 🔧 Detecta início do arrasto manualmente
	gui_input.connect(_on_gui_input)

# ---------------------- 🔧 Detecta movimento do mouse ----------------------
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Verifica se há prato pronto pra arrastar
		if not used_ingredients.is_empty() or _is_recipe_fulfilled():
			print("🖱 Clique detectado — iniciando estado de drag manual.")
			if typeof(DragManager) != TYPE_NIL:
				DragManager.current_drag_type = DragManager.DragType.PLATE
			print("Tipo de clique", DragManager.current_drag_type)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if typeof(DragManager) != TYPE_NIL:
			print("🖱 Soltou mouse — encerrando drag manual.")
			DragManager.current_drag_type = DragManager.DragType.NONE


# ---------------------- CONFIGURAÇÃO ----------------------
func set_current_recipe(recipe: RecipeResource) -> void:
	expected_recipe = recipe
	clear_ingredients()

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


# ---------------------- ADIÇÃO DE INGREDIENTES ----------------------
func add_ingredients(ingredients: Array[Dictionary]) -> void:
	if expected_recipe == null:
		print("⚠️ DropPlateArea.add_ingredients(): receita ainda não definida! Tentando recuperar...")
		_try_recover_recipe()
		if expected_recipe == null:
			push_warning("❌ Nenhuma receita disponível — ignorando ingredientes.")
			return

	for ing in ingredients:
		used_ingredients.append(ing)

	print("🧂 Ingredientes adicionados:", ingredients)
	_update_ingredient_list_ui()
	_update_plate_visuals()


func _try_recover_recipe() -> void:
	var ms := get_tree().current_scene
	if ms != null:
		var maybe : Variant = null
		if ms.has_method("get"):
			maybe = ms.get("current_recipe")
		if maybe:
			expected_recipe = maybe
			print("♻️ Receita recuperada automaticamente do MainScene:", expected_recipe.recipe_name)
			return

	if Managers != null and Managers.has_method("get_current_recipe"):
		var mr : Variant = Managers.get_current_recipe()
		if mr:
			expected_recipe = mr
			print("♻️ Receita recuperada automaticamente do Managers.")
			return

	print("⚠️ _try_recover_recipe(): não foi possível recuperar recipe automaticamente.")


# ---------------------- BUSCA DE SPRITES ----------------------
func _get_plate_sprite_for(id: String, state: String, quantity: int = 1) -> Texture2D:
	var st := (state if state != null else "").to_lower()
	var id_lower := (id if id != null else "").to_lower()

	var quantity_suffixes := [
		"%s_%d" % [st, quantity],  # ex: cooked_2
		"qty%d" % quantity,         # ex: qty2
		"count%d" % quantity,       # ex: count2
		st                          # ex: cooked
	]

	if expected_recipe and expected_recipe.plate_ingredient_visuals:
		for vis in expected_recipe.plate_ingredient_visuals:
			if vis == null or vis.ingredient_id == "":
				continue
			if vis.ingredient_id.to_lower() == id_lower:
				var default_tex: Texture2D = null  # guarda sprite "default" se existir

				for entry in vis.state_sprites:
					if entry == null or entry.texture == null:
						continue
					var state_name := entry.state.to_lower()

					# guarda o default (sem estado definido)
					if state_name == "" or state_name == "default":
						default_tex = entry.texture

					# tenta correspondência com quantidades ou estado
					for variant in quantity_suffixes:
						if state_name == variant:
							return entry.texture

				# se não encontrou correspondência exata, retorna o default
				if default_tex != null:
					print("🎨 Usando sprite default para", id_lower)
					return default_tex

	# fallback: IngredientDatabase
	if Managers and Managers.ingredient_database:
		for variant in quantity_suffixes:
			var tex := Managers.ingredient_database.get_sprite(id, variant)
			if tex:
				return tex

		# tenta pegar sprite genérico do ingrediente cru
		var base_tex := Managers.ingredient_database.get_sprite(id, "raw")
		if base_tex:
			return base_tex

	print("❌ Nenhum sprite encontrado para:", id, "state:", st, "qtd:", quantity)
	return null




# ---------------------- VISUAIS ----------------------
func _update_plate_visuals() -> void:
	if expected_recipe == null:
		print("⚠️ _update_plate_visuals() chamado sem receita.")
		return

	for n in _visual_nodes:
		if n and n.is_inside_tree():
			n.queue_free()
	_visual_nodes.clear()

	var has_sprites := false

	# prato final completo
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
		# conta quantidades de cada ingrediente (por id + state)
		var qty_map := {}
		for ing in used_ingredients:
			var key := "%s|%s" % [ing["id"], ing["state"]]
			qty_map[key] = qty_map.get(key, 0) + 1

		for key in qty_map.keys():
			var parts : PackedStringArray = key.split("|")
			var id : String = parts[0]
			var st : String = parts[1]
			var count : int = qty_map[key]
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


# ---------------------- CENTRALIZAÇÃO ----------------------
func _center_visual_position_for(node: Control) -> Vector2:
	await get_tree().process_frame
	var vc_size := visual_container.size
	if vc_size == Vector2.ZERO:
		vc_size = visual_container.get_combined_minimum_size()
		if vc_size == Vector2.ZERO:
			vc_size = size
	var node_size := node.custom_minimum_size
	if node_size == Vector2.ZERO:
		node_size = PLATE_SPRITE_SIZE
	return (vc_size - node_size) / 2.0


# ---------------------- OFFSET / Z-INDEX ----------------------
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


# ---------------------- CHECAGEM DE COMPLETUDE ----------------------
func _is_recipe_fulfilled() -> bool:
	if expected_recipe == null:
		return false

	var need := {}
	for req in expected_recipe.ingredient_requirements:
		if req == null:
			continue
		var key := "%s|%s" % [req.ingredient_id, req.state]
		need[key] = need.get(key, 0) + int(req.quantity)

	var have := {}
	for ing in used_ingredients:
		var key := "%s|%s" % [ing.get("id", ""), ing.get("state", "")]
		have[key] = have.get(key, 0) + 1

	for key in need.keys():
		if have.get(key, 0) < need[key]:
			return false
	return true


# ---------------------- DRAG & DROP ----------------------
func _get_drag_data(_pos: Vector2) -> Variant:
	if used_ingredients.is_empty() and not _is_recipe_fulfilled():
		print("⚠️ Nenhum ingrediente no prato — não arrastando.")
		return null

	print("🍽 Iniciando drag de prato...")
	if typeof(DragManager) != TYPE_NIL:
		DragManager.current_drag_type = DragManager.DragType.PLATE

	var wrapper := Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE


	# prato de fundo
	var plate_tex := texture
	if plate_tex:
		var plate_sprite := TextureRect.new()
		plate_sprite.texture = plate_tex
		plate_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plate_sprite.size = PLATE_SPRITE_SIZE
		wrapper.add_child(plate_sprite)

	# ingredientes visuais
	for node in _visual_nodes:
		if node and node.texture:
			var clone := TextureRect.new()
			clone.texture = node.texture
			clone.stretch_mode = node.stretch_mode
			clone.size = node.size
			clone.position = node.position
			clone.mouse_filter = Control.MOUSE_FILTER_IGNORE
			wrapper.add_child(clone)

	wrapper.position = PLATE_DRAG_OFFSET
	set_drag_preview(wrapper)

	return {
		"type": "plate",
		"ingredients": used_ingredients.duplicate(true),
		"source": self
	}



func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and (
		(data.has("type") and data["type"] == "cooked_tool") or
		(data.has("id") and data.has("state"))
	)


func _drop_data(_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_position, data):
		return

	var ingredients_to_add: Array[Dictionary] = []
	if data.has("type") and data["type"] == "cooked_tool":
		if data.has("ingredients"):
			ingredients_to_add = data["ingredients"]
		var src: Control = data.get("source", null)
		if src and src.is_inside_tree():
			src.queue_free()
	else:
		ingredients_to_add.append({
			"id": data.get("id", ""),
			"state": data.get("state", "")
		})

	add_ingredients(ingredients_to_add)


# ---------------------- 🔧 DRAG STATE HANDLING ----------------------
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if typeof(DragManager) != TYPE_NIL:
			print("🛑 Drag encerrado no DropPlateArea.")
			DragManager.current_drag_type = DragManager.DragType.NONE



# ---------------------- VISUAL DE ERRO ----------------------
func _flash_wrong_ing_visual(ing: Dictionary) -> void:
	var id: String = ing.get("id", "")
	var st: String = ing.get("state", "")
	var tex := _get_plate_sprite_for(id, st)
	if tex == null:
		return
	var node := TextureRect.new()
	node.texture = tex
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.modulate = Color(1, 0.4, 0.4)
	node.custom_minimum_size = PLATE_SPRITE_SIZE
	node.size = PLATE_SPRITE_SIZE
	node.position = await _center_visual_position_for(node)
	visual_container.add_child(node)
	await get_tree().create_timer(0.25).timeout
	if node.is_inside_tree():
		node.queue_free()


# ---------------------- LISTAGEM TEXTUAL ----------------------
func _update_ingredient_list_ui() -> void:
	for c in used_list.get_children():
		c.queue_free()

	var count_map := {}
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


# ---------------------- UTILITÁRIO ----------------------
func _ingredient_is_expected(ing: Dictionary) -> bool:
	if expected_recipe == null:
		return true
	for req in expected_recipe.ingredient_requirements:
		if req and req.ingredient_id == ing.get("id", ""):
			return true
	return false
