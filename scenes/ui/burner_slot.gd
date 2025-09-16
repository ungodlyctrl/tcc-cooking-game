extends Control
class_name BurnerSlot

## Boca do fogão. Aceita ferramenta (panela/frigideira) e ingredientes.
## Inicia um CookingMinigame local e, ao terminar, cria um CookedTool.

# ---------------- Enums ----------------
enum State { EMPTY, LOADED, COOKING }

# ---------------- Constants ----------------
const TOOL_IDS: Array[String] = ["panela", "frigideira"]

# Chaves usadas no dicionário de drag & drop
const KEY_ID := "id"
const KEY_STATE := "state"
const KEY_SOURCE := "source"
const STATE_TOOL := "tool"

# ---------------- Exports ----------------
@export var auto_start_on_first_ingredient: bool = false
@export var minigame_scene: PackedScene = preload("res://scenes/minigames/cooking_minigame.tscn")
@export var cooked_tool_scene: PackedScene = preload("res://scenes/ui/cooked_tool.tscn")

# ---------------- Vars ----------------
var state: State = State.EMPTY
var current_tool_id: String = ""
var ingredient_queue: Array[Dictionary] = []

# ---------------- Onready ----------------
@onready var tool_anchor: TextureRect = $ToolAnchor
@onready var start_button: Button = $StartButton


func _ready() -> void:
	## Configuração inicial
	mouse_filter = Control.MOUSE_FILTER_PASS
	start_button.pressed.connect(_on_start_pressed)
	_update_ui()


## Verifica se o dado arrastado pode ser aceito pelo slot.
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false

	if data.get(KEY_STATE, "") == STATE_TOOL:
		return data.get(KEY_ID, "") in TOOL_IDS and state == State.EMPTY

	# Ingredientes só podem ser aceitos se já houver uma ferramenta carregada
	if state != State.COOKING and current_tool_id != "":
		return data.get(KEY_STATE, "") != ""

	return false


## Trata o drop de ferramenta ou ingrediente.
func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return

	if data.get(KEY_STATE, "") == STATE_TOOL:
		# Carregar ferramenta
		current_tool_id = data.get(KEY_ID, "")
		_show_tool(current_tool_id)
		state = State.LOADED
		_update_ui()
	else:
		# Enfileirar ingrediente
		ingredient_queue.append({
			KEY_ID: data.get(KEY_ID, ""),
			KEY_STATE: data.get(KEY_STATE, "")
		})
		_update_ui()

	# Remove o nó de origem se ele existir na árvore
	var src: Node = data.get(KEY_SOURCE, null)
	if src and src.is_inside_tree():
		src.queue_free()

	DragManager.current_drag_type = DragManager.DragType.NONE

	# Auto-start opcional
	if auto_start_on_first_ingredient and state == State.LOADED and not ingredient_queue.is_empty():
		_start_minigame()


## Mostra o sprite da ferramenta na âncora.
func _show_tool(tool_id: String) -> void:
	var path: String = "res://assets/utensilios/%s.png" % tool_id
	tool_anchor.texture = load(path)
	tool_anchor.visible = true


## Atualiza elementos visuais de interface.
func _update_ui() -> void:
	start_button.visible = (state == State.LOADED and not ingredient_queue.is_empty())


## Handler para clique no botão "Iniciar".
func _on_start_pressed() -> void:
	if state == State.LOADED and not ingredient_queue.is_empty():
		_start_minigame()


## Instancia e inicia o CookingMinigame.
func _start_minigame() -> void:
	state = State.COOKING
	_update_ui()

	var game: CookingMinigame = minigame_scene.instantiate() as CookingMinigame
	add_child(game)

	game.show_background = false
	game.attach_to_anchor(tool_anchor)
	game.initialize(current_tool_id, ingredient_queue.duplicate(true))
	game.finished.connect(_on_minigame_finished)

	# Oculta o ícone do utensílio enquanto o minigame roda
	tool_anchor.visible = false


## Callback chamado quando o minigame termina.
func _on_minigame_finished(result_ingredients: Array[Dictionary], tool_type: String, quality: String) -> void:
	# Instancia o CookedTool
	var cooked: CookedTool = cooked_tool_scene.instantiate() as CookedTool

	# Configura os dados antes de adicionar à cena
	cooked.tool_type = tool_type
	cooked.cooked_ingredients = result_ingredients

	# Adiciona no PrepArea
	var prep_area: Control = get_node("/root/%s/Mode_Preparation/ScrollContainer/PrepArea" % get_tree().current_scene.name)
	prep_area.add_child(cooked)

	# Posiciona no mesmo lugar da âncora
	cooked.global_position = tool_anchor.global_position

	# Reset do slot
	current_tool_id = ""
	ingredient_queue.clear()  ## <<< 🔥 limpa ingredientes antigos
	state = State.EMPTY
	tool_anchor.visible = false
	tool_anchor.texture = null
	_update_ui()
