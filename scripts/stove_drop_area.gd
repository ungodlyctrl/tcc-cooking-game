extends TextureRect
class_name StoveDropArea

@onready var tool_visual: TextureRect = $ToolVisual

var current_tool: String = ""
var current_ingredient: String = ""
var active: bool = false


func _can_drop_data(_position, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("id") or not data.has("state"):
		return false

	# Sempre aceitar ferramenta se ainda não tem ingrediente
	if data["id"] in ["panela", "frigideira"] and data["state"] == "tool":
		return current_ingredient == ""

	# Só aceitar ingrediente se já tem uma ferramenta
	if data["state"] in ["raw", "cut"]:
		return current_tool != ""

	return false


func _drop_data(_position, data):
	if not _can_drop_data(_position, data):
		return

	if data["state"] == "tool":
		# Substituir ferramenta anterior
		current_tool = data["id"]
		_update_tool_visual(current_tool)
		tool_visual.visible = true

	elif data["state"] in ["raw", "cut"] and current_tool != "":
		# Iniciar minigame
		current_ingredient = data["id"]
		_start_cooking_minigame(current_tool, current_ingredient)

		# Resetar estado
		current_tool = ""
		current_ingredient = ""
		tool_visual.visible = false

	DragManager.current_drag_type = DragManager.DragType.NONE


func _update_tool_visual(tool_type: String) -> void:
	tool_visual.texture = load("res://assets/utensilios/%s.png" % tool_type)
	tool_visual.visible = true


func _start_cooking_minigame(tool_type: String, ingredient_name: String) -> void:
	var minigame := preload("res://scenes/minigames/cooking_minigame.tscn").instantiate()
	minigame.tool_type = tool_type
	minigame.ingredient_name = ingredient_name

	var prep_area := get_parent()
	prep_area.add_child(minigame)
	minigame.position = self.position

	minigame.tree_exited.connect(func():
		if is_instance_valid(tool_visual):
			tool_visual.visible = false
	)
