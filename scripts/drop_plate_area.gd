# DropPlateArea.gd
extends TextureRect
class_name DropPlateArea

## Área onde o jogador monta o prato com sprites modulares.
## Mostra sprites específicos definidos na receita (RecipeResource.plate_ingredient_visuals)
## e, se faltar algo, usa fallback da IngredientDatabase.

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
	if expected_recipe:
		# safe print (expected_recipe não é nulo)
		print("🔁 Receita já estava setada:", expected_recipe.recipe_name)
		_update_plate_visuals()
	else:
		print("🔁 Nenhuma receita atribuída ainda no DropPlateArea.")


# ---------------------- CONFIGURAÇÃO ----------------------
func set_current_recipe(recipe: RecipeResource) -> void:
	expected_recipe = recipe
	clear_ingredients()

	if expected_recipe:
		print("✅ DropPlateArea recebeu receita:", expected_recipe.recipe_name)
	else:
		print("⚠️ DropPlateArea recebeu receita nula.")

	# marcaremos ready e forçamos atualização visual (se possível)
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
	# Se não houver receita configurada, tenta recuperar automaticamente do MainScene
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
	# tentativa 1: pegar de get_tree().current_scene.current_recipe (MainScene guarda current_recipe)
	var ms := get_tree().current_scene
	if ms:
		# usamos get() para evitar chamadas diretas que podem causar erro
		var maybe : Variant = null
		# Em muitas cenas, get("current_recipe") retorna null se não existir; tentamos com segurança.
		# Nota: se sua MainScene usa outro nome, adapte aqui.
		maybe = ms.get("current_recipe") if ms.has_method("get") else null
		if maybe:
			expected_recipe = maybe
			print("♻️ Receita recuperada automaticamente do MainScene:", expected_recipe.recipe_name)
			return

	# tentativa 2: se houver um Manager global com receita atual (opcional, caso você tenha)
	if Managers and Managers.has_method("get_current_recipe"):
		var mr : Variant = Managers.get_current_recipe()
		if mr:
			expected_recipe = mr
			print("♻️ Receita recuperada automaticamente do Managers.")
			return

	# falha
	print("⚠️ _try_recover_recipe(): não foi possível recuperar recipe automaticamente.")


# ---------------------- BUSCA DE SPRITES ----------------------
func _get_plate_sprite_for(id: String, state: String) -> Texture2D:
	var st := (state if state != null else "").to_lower()
	var id_lower := (id if id != null else "").to_lower()

	# 1️⃣ Sprite definido na receita (caso exista)
	if expected_recipe and expected_recipe.plate_ingredient_visuals:
		for vis in expected_recipe.plate_ingredient_visuals:
			if vis == null:
				continue
			if vis.ingredient_id == "":
				continue
			if vis.ingredient_id.to_lower() == id_lower:
				# percorre lista de IngredientStateSprite (state + texture)
				for entry in vis.state_sprites:
					if entry == null:
						continue
					# entry.texture pode ser nulo
					if entry.state.to_lower() == st and entry.texture:
						print("🎨 Sprite da receita encontrado:", id, "state:", st)
						return entry.texture
				# fallback default
				for entry in vis.state_sprites:
					if entry and entry.state.to_lower() == "default" and entry.texture:
						print("🎨 Sprite da receita (default) usado para:", id)
						return entry.texture
				# fallback: primeiro disponível
				for entry in vis.state_sprites:
					if entry and entry.texture:
						print("🎨 Sprite da receita (primeiro disponível) usado:", id)
						return entry.texture

	# 2️⃣ Fallback: IngredientDatabase (caso exista)
	if Managers and Managers.ingredient_database:
		var tex := Managers.ingredient_database.get_sprite(id, st)
		if tex:
			print("⚙️ Sprite da IngredientDatabase usado para:", id, "state:", st)
			return tex
		var tex2 := Managers.ingredient_database.get_sprite(id, state)
		if tex2:
			print("⚙️ Sprite da IngredientDatabase (fallback sem lower) usado:", id)
			return tex2

	# 3️⃣ Falha total
	print("❌ Nenhum sprite encontrado para:", id, "state:", st)
	return null


# ---------------------- VISUAIS ----------------------
func _update_plate_visuals() -> void:
	if expected_recipe == null:
		print("⚠️ _update_plate_visuals() chamado sem receita.")
		return

	# safe-read do nome para log
	var rname := "(sem nome)"
	if expected_recipe and expected_recipe.has_method("get") == false:
		# some Resources não expõem has_method("get") - apenas tentamos acessar com segurança
		rname = str(expected_recipe.recipe_name) if expected_recipe else rname
	else:
		# tentativa mais direta
		rname = expected_recipe.recipe_name if expected_recipe else rname

	print("🎨 Atualizando visuais do prato — receita:", rname)
	print("🍽 Ingredientes atuais:", used_ingredients)

	if not visual_container:
		print("❌ visual_container não encontrado!")
		return
	else:
		print("✅ visual_container encontrado:", visual_container.name)

	# Limpa visuais anteriores
	for n in _visual_nodes:
		if n and n.is_inside_tree():
			n.queue_free()
	_visual_nodes.clear()

	# Prato completo → mostra sprite finalizado
	if _is_recipe_fulfilled() and expected_recipe.final_plate_sprite:
		var spr := TextureRect.new()
		spr.texture = expected_recipe.final_plate_sprite
		spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spr.custom_minimum_size = PLATE_SPRITE_SIZE
		spr.size = PLATE_SPRITE_SIZE
		spr.position = await _center_visual_position_for(spr)
		visual_container.add_child(spr)
		_visual_nodes.append(spr)
		print("✅ Sprite final do prato exibido.")
		return

	# Caso contrário, mostra sprites modulares dos ingredientes (ordem)
	var idx := 0
	for ing in used_ingredients:
		# garantir tipos corretos
		var id: String = str(ing.get("id", ""))
		var st: String = str(ing.get("state", ""))
		var tex: Texture2D = _get_plate_sprite_for(id, st)
		if tex == null:
			print("⚠️ Sprite não encontrado para", id, "state:", st, "- pulando.")
			continue

		var node := TextureRect.new()
		node.texture = tex
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		node.custom_minimum_size = PLATE_SPRITE_SIZE
		node.size = PLATE_SPRITE_SIZE

		# centraliza + offset
		node.position = await _center_visual_position_for(node) + _get_offset_for(id)
		node.z_index = _get_z_for(id, idx)

		visual_container.add_child(node)
		_visual_nodes.append(node)

		print("✅ Sprite adicionado ao prato:", id, "state:", st)
		idx += 1


# ---------------------- CENTRALIZAÇÃO ----------------------
func _center_visual_position_for(node: Control) -> Vector2:
	# espera frame para garantir sizes corretos
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
func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.has("type") and data["type"] == "cooked_tool":
		return true
	if data.has("id") and data.has("state"):
		return true
	return false


func _drop_data(_position: Vector2, data: Variant) -> void:
	print("🍞 DropPlateArea recebeu drop:", data)

	if not _can_drop_data(_position, data):
		return

	var ingredients_to_add: Array[Dictionary] = []

	if data.has("type") and data["type"] == "cooked_tool":
		if data.has("ingredients"):
			ingredients_to_add = data["ingredients"]
	else:
		ingredients_to_add.append({
			"id": data.get("id", ""),
			"state": data.get("state", "")
		})

	# mostra feedback visual de ingrediente inválido (aguarda se necessário)
	for ing in ingredients_to_add:
		if not _ingredient_is_expected(ing):
			await _flash_wrong_ing_visual(ing)

	add_ingredients(ingredients_to_add)
	# atualiza placar
	if get_tree().current_scene and get_tree().current_scene.has_method("update_score_display"):
		get_tree().current_scene.update_score_display()
	else:
		# tentativa segura (MainScene costuma ter update_score_display)
		pass


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
	# limpa lista textual
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

	# atualiza visuais após montar a lista
	_update_plate_visuals()


# ---------------------- UTILITÁRIO ----------------------
func _ingredient_is_expected(ing: Dictionary) -> bool:
	# se não houver receita definida aceitamos (compatibilidade)
	if expected_recipe == null:
		return true
	for req in expected_recipe.ingredient_requirements:
		if req and req.ingredient_id == ing.get("id", ""):
			return true
	return false
