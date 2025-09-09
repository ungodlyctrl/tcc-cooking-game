extends TextureRect
class_name StoveDropArea

@onready var tool_visual: TextureRect = $ToolVisual
@onready var start_button := $StartButton  # botão para iniciar o preparo
@onready var feedback_label: Label = $FeedbackLabel  # Novo: usado pra mostrar ingredientes por texto

var current_tool: String = ""
var ingredient_queue: Array[Dictionary] = []
var active: bool = false


func _ready():
	start_button.visible = false
	start_button.pressed.connect(_on_start_button_pressed)
	feedback_label.text = ""
	
	
func _can_drop_data(_position, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("id") or not data.has("state"):
		return false

	# Sempre aceitar ferramenta se ainda não tem ingrediente
	if data["id"] in ["panela", "frigideira"] and data["state"] == "tool":
		return not active

	# Só aceitar ingrediente se já tem uma ferramenta
	if data["state"] in ["raw", "cut"]:
		return current_tool != "" and not active

	return false


func _drop_data(_position, data):
	if not _can_drop_data(_position, data):
		return

	if data["state"] == "tool":
		current_tool = data["id"]
		_update_tool_visual(current_tool)
		tool_visual.visible = true

	elif data["state"] in ["raw", "cut"] and current_tool != "":
		# Adiciona ingrediente à fila
		ingredient_queue.append(data)
		_show_ingredient_feedback(data)
		start_button.visible = true
		
	# Encontra o nó do ingrediente (se veio por drag)
	var dragged_node = data.get("source", null)
	if dragged_node and dragged_node.is_inside_tree():
		dragged_node.queue_free()

	DragManager.current_drag_type = DragManager.DragType.NONE


# Declaração correta da função logo abaixo
func _show_ingredient_feedback(data: Dictionary) -> void:
	var name : String = IngredientDatabase.get_display_name(data["id"], data.get("state", "raw"))
	feedback_label.text += "- " + name + "\n"


func _update_tool_visual(tool_type: String) -> void:
	tool_visual.texture = load("res://assets/utensilios/%s.png" % tool_type)
	tool_visual.visible = true


func _on_start_button_pressed() -> void:
	if active or ingredient_queue.is_empty():
		return

	_start_cooking_minigame(current_tool, ingredient_queue.duplicate())
	ingredient_queue.clear()
	feedback_label.text = ""
	# Oculta botão, trava novamente a ferramenta
	start_button.visible = false
	active = true
	
func _start_cooking_minigame(tool_type: String, ingredient_list: Array[Dictionary]) -> void:
	var minigame := preload("res://scenes/minigames/cooking_minigame.tscn").instantiate()
	minigame.tool_type = tool_type
	minigame.ingredient_data_list = ingredient_list  # <- lista nova
	minigame.tool_global_position = tool_visual.global_position  # ← NOVO

	var prep_area := get_parent()
	prep_area.add_child(minigame)
	minigame.global_position = tool_visual.global_position  # ← Alinha o minigame

	minigame.tree_exited.connect(func():
		current_tool = ""
		active = false
		tool_visual.visible = false
)


func notify_cooked_result(result_ingredients: Array[Node]) -> void:
	# Cria a ferramenta pronta (panela/frigideira com comida)
	var cooked_tool := preload("res://scenes/ui/cooked_tool.tscn").instantiate()
	cooked_tool.set_tool(current_tool)
	cooked_tool.set_contents(result_ingredients)

	var prep_area := get_parent()
	prep_area.add_child(cooked_tool)
	cooked_tool.position = self.position

	# Reset da área
	current_tool = ""
	active = false
	start_button.visible = false
	tool_visual.visible = false
	feedback_label.text = ""
