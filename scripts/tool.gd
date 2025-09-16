extends Control
class_name Tool

## Representa uma ferramenta de preparo (ex: panela, frigideira).
## Pode ser arrastada para o BurnerSlot ou outras áreas compatíveis.


# ---------------- Constants ----------------
const STATE_TOOL := "tool"


# ---------------- Exports ----------------
@export var tool_id: String = "frigideira"   ## Identificador da ferramenta


# ---------------- Onready ----------------
@onready var icon: TextureRect = $Icon


func _ready() -> void:
	## Evita capturar o clique no control pai
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	## Carrega ícone inicial
	if icon:
		icon.texture = load("res://assets/utensilios/%s.png" % tool_id)


## Retorna dados para operação de drag-and-drop.
## NOTE: Não retorna `self` como source — retorna uma cópia não adicionada à árvore.
func _get_drag_data(event_position: Vector2) -> Dictionary:
	if not icon.get_rect().has_point(event_position):
		return {}

	# Cria uma cópia da ferramenta como "source"
	var source_instance: Tool = self.duplicate() as Tool
	source_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	source_instance.tool_id = tool_id

	# Cria preview visual para o cursor
	var preview: Tool = source_instance.duplicate() as Tool
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.tool_id = tool_id
	set_drag_preview(preview)

	# Marca tipo de drag
	DragManager.current_drag_type = DragManager.DragType.TOOL

	return {
		"id": tool_id,
		"state": STATE_TOOL,
		"source": source_instance
	}


func _notification(what: int) -> void:
	## Garante que o DragManager volte ao neutro ao fim do drag
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE
