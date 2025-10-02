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

@onready var tool_anchor: TextureRect = $ToolAnchor
@onready var start_button: Button = $StartButton

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	start_button.pressed.connect(_on_start_pressed)
	_update_ui()


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false

	# Caso 1: é uma tool (panela / frigideira)
	if data.get(KEY_STATE, "") == STATE_TOOL:
		# pode se o slot estiver vazio OU já tiver uma tool carregada (mas não cozinhando)
		return data.get(KEY_ID, "") in TOOL_IDS and state != State.COOKING

	# Caso 2: é ingrediente
	if state == State.LOADED and current_tool_id != "":
		return data.get(KEY_STATE, "") != ""

	return false

func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return

	if data.get(KEY_STATE, "") == STATE_TOOL:
		# Substituir tool atual (se existir)
		if current_tool_id != "":
			_clear_tool()

		current_tool_id = data.get(KEY_ID, "")
		_show_tool(current_tool_id)
		state = State.LOADED
		_update_ui()
	else:
		# adiciona ingrediente
		ingredient_queue.append({
			KEY_ID: data.get(KEY_ID, ""),
			KEY_STATE: data.get(KEY_STATE, "")
		})
		_update_ui()

	# remove origem
	var src: Node = data.get(KEY_SOURCE, null)
	if src and src.is_inside_tree():
		src.queue_free()

	DragManager.current_drag_type = DragManager.DragType.NONE

	if auto_start_on_first_ingredient and state == State.LOADED and not ingredient_queue.is_empty():
		_start_minigame()

func _show_tool(tool_id: String) -> void:
	var path: String = "res://assets/utensilios/%s.png" % tool_id
	tool_anchor.texture = load(path)
	tool_anchor.visible = true


func _clear_tool() -> void:
	ingredient_queue.clear()
	current_tool_id = ""
	tool_anchor.texture = null
	tool_anchor.visible = false
	state = State.EMPTY

func _update_ui() -> void:
	start_button.visible = (state == State.LOADED and not ingredient_queue.is_empty())

func _on_start_pressed() -> void:
	if state == State.LOADED and not ingredient_queue.is_empty():
		_start_minigame()

func _start_minigame() -> void:
	state = State.COOKING
	_update_ui()

	var game: CookingMinigame = minigame_scene.instantiate() as CookingMinigame
	add_child(game)

	game.show_background = false
	game.attach_to_anchor(tool_anchor)
	game.initialize(current_tool_id, ingredient_queue.duplicate(true))
	game.finished.connect(_on_minigame_finished)

	tool_anchor.visible = false

func _on_minigame_finished(result_ingredients: Array[Dictionary], tool_type: String, quality: String) -> void:
	var cooked: CookedTool = cooked_tool_scene.instantiate() as CookedTool
	cooked.tool_type = tool_type
	cooked.cooked_ingredients = result_ingredients

	var prep_area: Control = get_node("/root/%s/Mode_Preparation/ScrollContainer/PrepArea" % get_tree().current_scene.name)
	if prep_area:
		cooked.set_meta("is_dynamic", true)
		prep_area.add_child(cooked)
		cooked.global_position = tool_anchor.global_position

	_clear_tool()
	_update_ui()
