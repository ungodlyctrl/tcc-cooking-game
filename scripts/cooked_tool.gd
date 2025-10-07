extends Control
class_name CookedTool

## Representa a ferramenta (panela/frigideira) com ingredientes já preparados.
## Pode ser arrastada para o prato (DropPlateArea) ou descartada.

const STATE_COOKED_TOOL := "cooked_tool"

# 🔹 Offsets de preview por tipo de utensílio
const TOOL_DRAG_OFFSETS := {
	"panela": Vector2(-32, -16),
	"frigideira": Vector2(-24, -12)
}

@export var tool_type: String = ""
@export var cooked_ingredients: Array[Dictionary] = []

@onready var tool_sprite: TextureRect = $ToolSprite
@onready var ingredients_label: Label = $IngredientsLabel


func _ready() -> void:
	_load_tool_sprite()
	_update_ingredients_label()
	add_to_group("day_temp")


func _load_tool_sprite() -> void:
	if tool_type == "":
		return
	var path := "res://assets/utensilios/%s.png" % tool_type
	tool_sprite.texture = load(path)


func _update_ingredients_label() -> void:
	var names: Array[String] = []
	for data in cooked_ingredients:
		var id: String = data.get("id", "???")
		var state: String = data.get("state", "")
		var quality: String = data.get("result", "")
		var ing: IngredientData = Managers.ingredient_database.get_ingredient(id)
		if ing:
			names.append("%s (%s/%s)" % [ing.display_name.capitalize(), state, quality])
		else:
			names.append(id)
	ingredients_label.text = "Ingredientes: " + ", ".join(names)


func _get_drag_data(_pos: Vector2) -> Dictionary:
	var preview_tex := load("res://assets/utensilios/%s.png" % tool_type)
	var preview := TextureRect.new()
	preview.texture = preview_tex
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var offset : Vector2 = TOOL_DRAG_OFFSETS.get(tool_type, Vector2.ZERO)
	var wrapper := Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(preview)
	preview.position = offset

	set_drag_preview(wrapper)
	DragManager.current_drag_type = DragManager.DragType.TOOL

	return {
		"type": STATE_COOKED_TOOL,
		"tool_type": tool_type,
		"ingredients": cooked_ingredients,
		"source": self
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE
