extends Control
class_name CookedTool

## Representa a ferramenta (panela/frigideira) com ingredientes já preparados.
## Pode ser arrastada para o prato (DropPlateArea) ou descartada.

# ---------------- Export ----------------
@export var tool_type: String = ""
@export var cooked_ingredients: Array[Dictionary] = []

# ---------------- Onready ----------------
@onready var tool_sprite: TextureRect = $ToolSprite
@onready var ingredients_label: Label = $IngredientsLabel


func _ready() -> void:
	## Visual da ferramenta
	var path: String = "res://assets/utensilios/%s.png" % tool_type
	tool_sprite.texture = load(path)
	
	## Feedback textual dos ingredientes
	var names: Array[String] = []
	for data in cooked_ingredients:
		var id: String = data.get("id", "???")
		var state: String = data.get("state", "")
		var quality: String = data.get("result", "")
		
		var ing: IngredientData = IngredientDatabase.get_ingredient(id)
		if ing:
			var display_name := ing.display_name
			names.append("%s (%s/%s)" % [display_name.capitalize(), state, quality])
		else:
			names.append(id)
	
	ingredients_label.text = "Ingredientes: " + ", ".join(names)
	
	add_to_group("day_temp")


func _get_drag_data(_pos: Vector2) -> Dictionary:
	## Prévia do drag
	var preview: Control = self.duplicate()
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)
	
	DragManager.current_drag_type = DragManager.DragType.TOOL
	
	return {
		"type": "cooked_tool",
		"tool_type": tool_type,
		"ingredients": cooked_ingredients,
		"source": self
	}


func _notification(what: int) -> void:
	## Garante que o DragManager volte ao neutro.
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE
