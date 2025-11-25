extends Control
class_name BowlArea

signal drag_state_changed(is_dragging: bool)

const PREVIEW_SIZE := Vector2(84, 88)
const DRAG_OFFSET := Vector2(-40, -30)

@onready var bowl_root: Control = $BowlRoot
@onready var bowl_base: TextureRect = $BowlRoot/BowlBase
@onready var mini_icons: HBoxContainer = $MiniIconsContainer

var ingredients: Array[Dictionary] = []     # [{ "id": String, "state": String }]
var mixed_item: Dictionary = {}            # { "mix_id": String, "sprite": Texture2D, "ingredients": Array[Dictionary] }

var _is_dragging_local := false
var _ready_finished := false

func _ready() -> void:
	await get_tree().process_frame
	_ready_finished = true

	# ===== ESSENCIAL: permitir receber drops =====
	# Godot 4.x usa `drop_mode`

	# Permitir eventos do mouse (para _get_drag_data quando arrastar do bowl)
	mouse_filter = Control.MOUSE_FILTER_PASS

	# conecta input do próprio control (para iniciar drag a partir do bowl)
	if not gui_input.is_connected(Callable(self, "_on_gui_input")):
		gui_input.connect(Callable(self, "_on_gui_input"))


# iniciar drag se o jogador clicar no bowl com conteúdo
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not ingredients.is_empty() or mixed_item.size() > 0:
				if typeof(DragManager) != TYPE_NIL:
					DragManager.current_drag_type = DragManager.DragType.INGREDIENT
		else:
			if typeof(DragManager) != TYPE_NIL:
				DragManager.current_drag_type = DragManager.DragType.NONE


# adicionar ingredientes (vindo de drop)
func add_ingredients(arr: Array[Dictionary]) -> void:
	if arr == null or arr.is_empty():
		return

	for ing in arr:
		if typeof(ing) == TYPE_DICTIONARY and ing.has("id") and ing.has("state"):
			ingredients.append({"id": str(ing["id"]), "state": str(ing["state"])})
	print("[BowlArea] add_ingredients =>", ingredients)
	_update_after_change()



func _update_after_change() -> void:
	_try_mix()
	_update_mini_icons()
	emit_signal("drag_state_changed", true)


# delega tentativa de mix para Managers.mix_manager se existir
func _try_mix() -> void:
	mixed_item.clear()
	if ingredients.is_empty():
		return

	if Managers != null and Managers.has_method("mix_manager") and Managers.mix_manager != null:
		if Managers.mix_manager.has_method("try_get_mix"):
			var result := Managers.mix_manager.try_get_mix(ingredients)
			if typeof(result) == TYPE_DICTIONARY and result.size() > 0:
				mixed_item = result.duplicate(true)
				print("🥣 Mix detectado:", mixed_item.get("mix_id", "??"))


# atualizar mini-icons (mostra ingredientes individuais ou do mix)
func _update_mini_icons() -> void:
	for c in mini_icons.get_children():
		c.queue_free()

	var list_to_show: Array = []
	if mixed_item.size() > 0 and mixed_item.has("ingredients"):
		list_to_show = mixed_item["ingredients"]
	else:
		list_to_show = ingredients

	for ing in list_to_show:
		var id = ing.get("id", "")
		var state = ing.get("state", "")
		var tex: Texture2D = null
		if Managers and Managers.ingredient_database:
			tex = Managers.ingredient_database.get_mini_icon(id, state)
		if tex == null:
			continue
		var icon := TextureRect.new()
		icon.texture = tex
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		mini_icons.add_child(icon)


func clear_ingredients() -> void:
	ingredients.clear()
	mixed_item.clear()
	for c in mini_icons.get_children():
		c.queue_free()
	_update_after_change()
	emit_signal("drag_state_changed", false)
	print("[BowlArea] clear_ingredients called")


# quando o bowl é arrastado (produz preview e payload)
func _get_drag_data(_position: Vector2) -> Variant:
	if ingredients.is_empty() and mixed_item.size() == 0:
		return null

	var preview := Control.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = PREVIEW_SIZE
	preview.size = PREVIEW_SIZE

	var tex: Texture2D = null
	if mixed_item.size() > 0 and mixed_item.has("sprite"):
		tex = mixed_item["sprite"]
	elif ingredients.size() > 0:
		var first := ingredients[0]
		if Managers and Managers.ingredient_database:
			tex = Managers.ingredient_database.get_mini_icon(first.get("id", ""), first.get("state", ""))

	if tex != null:
		var spr := TextureRect.new()
		spr.texture = tex
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		spr.custom_minimum_size = PREVIEW_SIZE
		spr.size = PREVIEW_SIZE
		spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.add_child(spr)

	preview.position = DRAG_OFFSET
	set_drag_preview(preview)

	# esconder visual do bowl durante drag
	_is_dragging_local = true
	if bowl_root:
		bowl_root.visible = false

	if typeof(DragManager) != TYPE_NIL:
		DragManager.current_drag_type = DragManager.DragType.INGREDIENT

	if mixed_item.size() > 0:
		return {
			"type": "mixed",
			"mix_id": mixed_item.get("mix_id", ""),
			"sprite": mixed_item.get("sprite", null),
			"ingredients": mixed_item.get("ingredients", []).duplicate(true),
			"source": self
		}

	return {
		"type": "ingredient_group",
		"ingredients": ingredients.duplicate(true),
		"source": self
	}


# o engine pergunta se pode dropar aqui
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	print("[BowlArea] _can_drop_data called. data type:", typeof(data))
	if typeof(data) != TYPE_DICTIONARY:
		return false

	# Bloqueia ferramentas
	if data.get("state", "") == "tool" or data.get("type", "") == "tool":
		return false

	# Aceita payloads com 'ingredients' ou (id+state)
	if data.has("ingredients") or (data.has("id") and data.has("state")):
		print("[BowlArea] _can_drop_data => TRUE (accepted format) ", data)
		return true

	# Aceita tipos comuns compatíveis (plate/cooked_tool/mixed/ingredient_group)
	if data.get("type","") in ["plate", "cooked_tool", "mixed", "ingredient_group"]:
		if data.has("ingredients"):
			print("[BowlArea] _can_drop_data => TRUE (type allowed)", data.get("type"))
			return true

	return false


# quando soltam o drag sobre o bowl
func _drop_data(_pos: Vector2, data: Variant) -> void:
	print("[BowlArea] _drop_data called with:", data)
	if not _can_drop_data(_pos, data):
		print("[BowlArea] drop rejected by _can_drop_data")
		return

	var arr: Array = []
	if data.has("ingredients"):
		arr = data["ingredients"]
	elif data.has("id") and data.has("state"):
		arr.append({"id": data.get("id", ""), "state": data.get("state","")})
	else:
		print("[BowlArea] unexpected drop format:", data)
		return

	add_ingredients(arr)
	_clear_source(data)


func _clear_source(data: Dictionary) -> void:
	var src = data.get("source", null)
	if src and src.is_inside_tree():
		src.queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if _is_dragging_local:
			_is_dragging_local = false
			if bowl_root:
				bowl_root.visible = true
			emit_signal("drag_state_changed", false)
		if typeof(DragManager) != TYPE_NIL:
			DragManager.current_drag_type = DragManager.DragType.NONE
