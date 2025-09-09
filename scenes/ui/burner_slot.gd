extends Control
class_name BurnerSlot

## Boca do fogão. Aceita ferramenta (panela/frigideira) e ingredientes,
## inicia um CookingMinigame local e, ao terminar, cria um CookedTool.

# ---------------- Enums ----------------
enum State { EMPTY, LOADED, COOKING }

# ---------------- Constants ----------------
const TOOL_IDS := ["panela", "frigideira"]

# ---------------- Export ----------------
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
	## Config inicial
	mouse_filter = Control.MOUSE_FILTER_PASS
	start_button.pressed.connect(_on_start_pressed)
	_update_ui()


## Aceita ferramenta (state == "tool") quando vazio,
## e ingredientes (raw/cut/etc.) quando já tem ferramenta e não está cozinhando.
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	if data.get("state", "") == "tool":
		return data.get("id", "") in TOOL_IDS and state == State.EMPTY
	
	# Ingrediente
	if state != State.COOKING and current_tool_id != "":
		var st: String = data.get("state", "")
		return st != ""  # aceitar qualquer estado válido que você use ("raw","cut",...)
	
	return false


func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return
	
	if data.get("state", "") == "tool":
		# Carregar ferramenta
		current_tool_id = data.get("id", "")
		print("🔥 current_tool_id recebido:", data.get("id", "NULO"))
		_show_tool(current_tool_id)
		state = State.LOADED
		_update_ui()
	else:
		# Enfileirar ingrediente
		ingredient_queue.append({
			"id": data.get("id", ""),
			"state": data.get("state", "")
		})
		_update_ui()

	# Se veio um nó de origem (arraste visual), removê-lo
	var src: Node = data.get("source", null)
	if src and src.is_inside_tree():
		src.queue_free()
	
	DragManager.current_drag_type = DragManager.DragType.NONE
	
	# Auto-start opcional
	if auto_start_on_first_ingredient and state == State.LOADED and ingredient_queue.size() > 0:
		_start_minigame()


## Mostra a sprite da ferramenta na âncora.
func _show_tool(tool_id: String) -> void:
	var path: String = "res://assets/utensilios/%s.png" % tool_id
	tool_anchor.texture = load(path)
	tool_anchor.visible = true


## Atualiza visibilidade de botão etc.
func _update_ui() -> void:
	start_button.visible = (state == State.LOADED and ingredient_queue.size() > 0)


## Clique no botão "Iniciar".
func _on_start_pressed() -> void:
	if state == State.LOADED and ingredient_queue.size() > 0:
		_start_minigame()


## Instancia um CookingMinigame como filho do Burner.
## Quando terminar, criamos um CookedTool e resetamos a boca.
func _start_minigame() -> void:
	state = State.COOKING
	_update_ui()

	var game: CookingMinigame = minigame_scene.instantiate() as CookingMinigame
	add_child(game)
	game.show_background = false
	game.attach_to_anchor(tool_anchor)
	game.initialize(current_tool_id, ingredient_queue.duplicate(true))  # <<< aqui
	game.finished.connect(_on_minigame_finished)

	# 🔥 Ocultar o ícone do utensílio enquanto o minigame roda
	tool_anchor.visible = false


func _on_minigame_finished(result_ingredients: Array[Dictionary], tool_type: String, quality: String) -> void:
	# Instancia o CookedTool
	var cooked: CookedTool = cooked_tool_scene.instantiate() as CookedTool

	# Configura os dados ANTES de adicionar à cena
	cooked.tool_type = tool_type
	cooked.cooked_ingredients = result_ingredients

	# Agora sim adiciona ao PrepArea
	var prep_area: Control = get_node("/root/%s/Mode_Preparation/ScrollContainer/PrepArea" % get_tree().current_scene.name)
	prep_area.add_child(cooked)

	# Posiciona no mesmo lugar do tool_anchor
	cooked.global_position = tool_anchor.global_position

	# Reset
	current_tool_id = ""
	state = State.EMPTY
	tool_anchor.visible = false
	tool_anchor.texture = null
	_update_ui()
