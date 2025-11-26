extends Control
class_name BurnerSlot

enum State { EMPTY, LOADED, COOKING }

const TOOL_IDS: Array[String] = ["panela", "frigideira"]
const KEY_ID := "id"
const KEY_STATE := "state"
const KEY_SOURCE := "source"
const STATE_TOOL := "tool"

@export var auto_start_on_first_ingredient: bool = false
@export var minigame_scene: PackedScene = preload("res://scenes/minigames/cooking_minigame.tscn")
@export var cooked_tool_scene: PackedScene = preload("res://scenes/ui/cooked_tool.tscn")

var state: State = State.EMPTY
var current_tool_id: String = ""
var ingredient_queue: Array[Dictionary] = []

# Nodes (expect these names exist in the scene)
@onready var tool_anchor: TextureRect = $ToolAnchor
@onready var mini_icons: HBoxContainer = $MiniIcons
@onready var start_btn_sprite: TextureRect = $StartButtonSprite
@onready var start_btn_outline: TextureRect = $StartButtonOutline

# tween for outline blink / rotation
var _outline_tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Start button input
	if start_btn_sprite:
		start_btn_sprite.mouse_filter = Control.MOUSE_FILTER_STOP
		start_btn_sprite.gui_input.connect(_on_start_gui_input)

	# make outline invisible initially
	if start_btn_outline:
		start_btn_outline.visible = false
		start_btn_outline.modulate.a = 1.0

	_update_ui()
	_update_mini_icons()


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false

	# TOOL (panela / frigideira)
	if data.get(KEY_STATE, "") == STATE_TOOL:
		# allow place if slot empty OR tool present and not cooking
		return data.get(KEY_ID, "") in TOOL_IDS and state != State.COOKING

	# INGREDIENT: only allow when a tool is loaded and tool present
	if state == State.LOADED and current_tool_id != "":
		# Must be an ingredient dict with id/state
		var id = data.get(KEY_ID, "")
		var st = data.get(KEY_STATE, "")
		if id == "" or st == "":
			return false

		# only allow raw or cut
		if st != "raw" and st != "cut":
			return false

		# must have a cooked/fried variant in ingredient database (depending on tool)
		if not _ingredient_has_cooked_variant(id):
			return false

		return true

	return false


func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return

	# TOOL placed
	if data.get(KEY_STATE, "") == STATE_TOOL:
		# replace existing tool (if any)
		if current_tool_id != "":
			_clear_tool()
		current_tool_id = data.get(KEY_ID, "")
		_show_tool(current_tool_id)
		state = State.LOADED
		_update_ui()
		_update_mini_icons()

		if current_tool_id == "panela":
			AudioManager.play_sfx(AudioManager.library.stove_place_pan)
		elif current_tool_id == "frigideira":
			AudioManager.play_sfx(AudioManager.library.stove_place_fryer)
	# INGREDIENT placed
	else:
		AudioManager.play_sfx(AudioManager.library.ingredient_drop)
		ingredient_queue.append({
			KEY_ID: data.get(KEY_ID, ""),
			KEY_STATE: data.get(KEY_STATE, "")
		})
		_update_ui()
		_update_mini_icons()

	# remove origin safely (se veio de outro BurnerSlot, chame remove_tool_from_burner)
	var src = data.get(KEY_SOURCE, null)

# 1. Veio de OUTRO BurnerSlot
	if src is BurnerSlot and src != self:
		# Só limpar se realmente era a ferramenta do slot anterior
		if src.current_tool_id == data.get(KEY_ID, ""):
			src._clear_tool()

	# 2. Veio da prateleira (Tool), mas apenas se era o original na árvore
	elif src is Tool and src.is_inside_tree():
		src.queue_free()



	DragManager.current_drag_type = DragManager.DragType.NONE

	if auto_start_on_first_ingredient and state == State.LOADED and not ingredient_queue.is_empty():
		_start_minigame()


func _show_tool(tool_id: String) -> void:
	if tool_id == "":
		return
	var path: String = "res://assets/utensilios/%s.png" % tool_id
	tool_anchor.texture = load(path)
	tool_anchor.visible = true

	# show outline blink on start button (indicate ready) only if there are ingredients
	if ingredient_queue.size() > 0:
		_start_outline_blink(true)
	else:
		_start_outline_blink(false)

	# ensure start button visible (but it will be hidden by _update_ui when not appropriate)
	start_btn_sprite.visible = true


func _clear_tool() -> void:
	ingredient_queue.clear()
	current_tool_id = ""
	tool_anchor.texture = null
	tool_anchor.visible = false
	state = State.EMPTY
	_update_mini_icons()
	_start_outline_blink(false)
	start_btn_sprite.visible = false
	# reset rotation of start button to default (important)
	if start_btn_sprite:
		start_btn_sprite.rotation_degrees = 0.0


func _update_ui() -> void:
	start_btn_sprite.visible = (state == State.LOADED and not ingredient_queue.is_empty())

	if state == State.LOADED and not ingredient_queue.is_empty():
		_start_outline_blink(true)
	else:
		_start_outline_blink(false)


func _on_start_pressed() -> void:
	if state == State.LOADED and not ingredient_queue.is_empty():
		_start_minigame()


# input handler for StartButtonSprite (texture rect)
func _on_start_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if state == State.LOADED and not ingredient_queue.is_empty():
			_start_minigame()


func _start_minigame() -> void:
	state = State.COOKING
	_update_ui()

	if current_tool_id == "frigideira":
		AudioManager.play_loop_sfx(AudioManager.library.sfx_fry_loop)
	else:
		AudioManager.play_loop_sfx(AudioManager.library.sfx_boiling_loop)

	# instantiate minigame and attach
	var game: CookingMinigame = minigame_scene.instantiate() as CookingMinigame
	add_child(game)
	game.show_background = false
	game.attach_to_anchor(tool_anchor)
	game.initialize(current_tool_id, ingredient_queue.duplicate(true))
	game.finished.connect(_on_minigame_finished)

	# hide the tool anchor while minigame runs
	tool_anchor.visible = false

	# rotate start button 90deg to indicate running (visual)
	_rotate_start_button(90)

	# stop outline blink while cooking
	_start_outline_blink(false)


func _on_minigame_finished(result_ingredients: Array[Dictionary], tool_type: String, quality: String) -> void:
	# instantiate cooked tool and drop into prep area (same as before)
	var cooked: CookedTool = cooked_tool_scene.instantiate() as CookedTool
	cooked.tool_type = tool_type
	cooked.cooked_ingredients = result_ingredients

	var prep_area: Control = get_node("/root/%s/Mode_Preparation/ScrollContainer/PrepArea" % get_tree().current_scene.name)
	if prep_area:
		cooked.set_meta("is_dynamic", true)
		prep_area.add_child(cooked)
		cooked.global_position = tool_anchor.global_position

	# show tool full sprite in anchor (cooked look) if you have a specific cooked sprite
	var cooked_path := "res://assets/utensilios/%s_full.png" % tool_type
	if ResourceLoader.exists(cooked_path):
		tool_anchor.texture = load(cooked_path)
		tool_anchor.visible = true
	else:
		tool_anchor.texture = null
		tool_anchor.visible = false

	_clear_tool()
	_update_ui()


# ---------- mini-icons (above tool) ----------
func _update_mini_icons() -> void:
	# clear existing
	for c in mini_icons.get_children():
		c.queue_free()

	# recreate from ingredient_queue
	for ing in ingredient_queue:
		var id : String = ing.get("id", "")
		var st : String = ing.get("state", "")
		var tex : Texture2D = null
		if Managers and Managers.ingredient_database:
			# prefer mini icon for state (current state)
			tex = Managers.ingredient_database.get_mini_icon(id, st)
			# fallback to raw mini icon
			if tex == null:
				tex = Managers.ingredient_database.get_mini_icon(id, "raw")
		if tex == null:
			continue
		var icon := TextureRect.new()
		icon.texture = tex
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mini_icons.add_child(icon)


# ---------- helpers ----------
func _ingredient_has_cooked_variant(id: String) -> bool:
	# returns true if ingredient has cooked or fried sprite available in DB
	if Managers == null or not Managers.has_method("ingredient_database"):
		# be permissive if DB not ready
		return true
	# check cooked/fried in database
	var cooked := Managers.ingredient_database.get_sprite(id, "cooked")
	var fried := Managers.ingredient_database.get_sprite(id, "fried")
	return cooked != null or fried != null


# --------- Start button outline blink & rotation ----------
func _start_outline_blink(enable: bool) -> void:
	if start_btn_outline == null:
		return
	if enable:
		start_btn_outline.visible = true
		# kill previous tween
		if _outline_tween and _outline_tween.is_valid():
			_outline_tween.kill()
		_outline_tween = create_tween()
		_outline_tween.set_loops()
		# stronger/faster blink
		_outline_tween.tween_property(start_btn_outline, "modulate:a", 0.2, 0.22)
		_outline_tween.tween_property(start_btn_outline, "modulate:a", 1.0, 0.22)
	else:
		if _outline_tween and _outline_tween.is_valid():
			_outline_tween.kill()
		start_btn_outline.visible = false
		start_btn_outline.modulate.a = 1.0


func _rotate_start_button(deg: float) -> void:
	# rotates the sprite smoothly by 'deg' degrees relative
	var tw = create_tween()
	tw.tween_property(start_btn_sprite, "rotation_degrees", start_btn_sprite.rotation_degrees + deg, 0.22)


# allow dragging tool out for trash (so tool_anchor supports _get_drag_data)
func _get_drag_data(_pos: Vector2) -> Variant:
	if current_tool_id == "" or state == State.COOKING:
		return null
	# preview visual
	var preview := TextureRect.new()
	preview.texture = tool_anchor.texture
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wrapper := Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(preview)
	set_drag_preview(wrapper)
	# esconder visual original
	tool_anchor.visible = false
	DragManager.current_drag_type = DragManager.DragType.TOOL
	return {
		"type": "tool",
		"id": current_tool_id,
		"state": STATE_TOOL,
		"source": self
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		# reset drag state
		if DragManager.current_drag_type == DragManager.DragType.TOOL:
			DragManager.current_drag_type = DragManager.DragType.NONE
		# se ainda estamos carregando a ferramenta, reexibir
		if current_tool_id != "" and state != State.COOKING:
			tool_anchor.visible = true


func remove_tool_from_burner():
	_clear_tool()
