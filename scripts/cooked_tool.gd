extends Control
class_name CookedTool

## Representa a ferramenta (panela/frigideira) com ingredientes já preparados.
## Pode ser arrastada para o prato (DropPlateArea) ou descartada.


# ---------------- Constants ----------------
const STATE_COOKED_TOOL := "cooked_tool"


# ---------------- Exports ----------------
@export var tool_type: String = ""   ## Identificador do utensílio (panela, frigideira etc.)
@export var cooked_ingredients: Array[Dictionary] = []   ## Lista de ingredientes preparados


# ---------------- Onready ----------------
@onready var tool_sprite: TextureRect = $ToolSprite
@onready var ingredients_label: Label = $IngredientsLabel


func _ready() -> void:
	## Configura a aparência inicial
	_load_tool_sprite()
	_update_ingredients_label()

	## Grupo temporário usado em gameplay
	add_to_group("day_temp")


## Carrega o sprite correspondente ao utensílio.
func _load_tool_sprite() -> void:
	if tool_type == "":
		return
	var path: String = "res://assets/utensilios/%s.png" % tool_type
	tool_sprite.texture = load(path)


## Atualiza o label textual com os ingredientes preparados.
func _update_ingredients_label() -> void:
	var names: Array[String] = []

	for data in cooked_ingredients:
		var id: String = data.get("id", "???")
		var state: String = data.get("state", "")
		var quality: String = data.get("result", "")

		var ing: IngredientData = IngredientDatabase.get_ingredient(id)
		if ing:
			var display_name: String = ing.display_name
			names.append("%s (%s/%s)" % [display_name.capitalize(), state, quality])
		else:
			names.append(id)

	ingredients_label.text = "Ingredientes: " + ", ".join(names)


## Inicia operação de drag-and-drop deste utensílio preparado.
func _get_drag_data(_pos: Vector2) -> Dictionary:
	# Prévia visual
	var preview: Control = self.duplicate()
	preview.modulate = Color(1.0, 1.0, 1.0, 1.0)
	set_drag_preview(preview)

	# Marca tipo de drag
	DragManager.current_drag_type = DragManager.DragType.TOOL

	return {
		"type": STATE_COOKED_TOOL,
		"tool_type": tool_type,
		"ingredients": cooked_ingredients,
		"source": self
	}


func _notification(what: int) -> void:
	## Garante que o DragManager volte ao neutro ao fim do drag
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE
