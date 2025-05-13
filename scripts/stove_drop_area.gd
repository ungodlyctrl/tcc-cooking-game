extends TextureRect

@onready var tool_visual := $ToolVisual

var current_tool: String = ""
var current_ingredient: String = ""
var active := false

func _can_drop_data(position, data):
	if typeof(data) != TYPE_DICTIONARY or not data.has("id") or not data.has("state"):
		return false

	if not active:
		# Primeira etapa: aceitar panela ou frigideira
		return data["id"] in ["panela", "frigideira"] and data["state"] == "tool"
	else:
		# Segunda etapa: aceitar ingrediente
		return data["state"] in ["raw", "cut"]

func _drop_data(position, data):
	if not _can_drop_data(position, data):
		print("❌ Drop inválido:", data)
		return

	if not active:
		# Primeiro drop: ferramenta
		current_tool = data["id"]
		_update_tool_visual(current_tool)
		active = true
		print("🍳 Ferramenta colocada:", current_tool)
	else:
		# Segundo drop: ingrediente → inicia minigame
		current_ingredient = data["id"]
		_start_cooking_minigame(current_tool, current_ingredient)
		active = false
		current_tool = ""
		current_ingredient = ""
		tool_visual.visible = false

	DragManager.current_drag_type = DragManager.DragType.NONE

func _update_tool_visual(tool_type: String):
	tool_visual.texture = load("res://assets/utensilios/%s.png" % tool_type)
	tool_visual.visible = true


func _start_cooking_minigame(tool_type: String, ingredient_name: String):
	var minigame = preload("res://scenes/minigames/cooking_minigame.tscn").instantiate()
	minigame.tool_type = tool_type
	minigame.ingredient_name = ingredient_name

	var prep_area := get_parent()  # Mais seguro

	prep_area.add_child(minigame)

	minigame.position = self.position


	minigame.tree_exited.connect(func():
		if is_instance_valid(tool_visual):
			tool_visual.visible = false
	)
