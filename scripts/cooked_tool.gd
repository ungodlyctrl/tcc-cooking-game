extends Control
class_name CookedTool

@export var tool_type: String = ""
@export var cooked_ingredients: Array[Dictionary] = []

@onready var tool_sprite: TextureRect = $ToolSprite
@onready var ingredients_label: Label = $IngredientsLabel

func _ready() -> void:
	# Carrega o sprite da ferramenta
	tool_sprite.texture = load("res://assets/utensilios/%s.png" % tool_type)

	# Feedback textual temporário com os ingredientes
	var names := []
	for data in cooked_ingredients:
		names.append(data.get("id", "???"))
	ingredients_label.text = "Ingredientes: " + ", ".join(names)
	add_to_group("day_temp")

func _get_drag_data(_position: Vector2) -> Dictionary:
	var preview := self.duplicate()
	preview.modulate = Color(1, 1, 1, 0.8)
	set_drag_preview(preview)

	DragManager.current_drag_type = DragManager.DragType.TOOL

	return {
		"type": "cooked_tool",
		"tool_type": tool_type,
		"ingredients": cooked_ingredients,
		"source": self
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		# Se a ferramenta não foi entregue corretamente, volta para a posição original
		await get_tree().process_frame
		if not get_global_rect().intersects(get_viewport_rect()):
			position = Vector2(position.x, position.y)  # placeholder para futura lógica de retorno
