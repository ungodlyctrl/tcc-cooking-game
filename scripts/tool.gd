extends Control
class_name Tool

## Representa uma ferramenta de preparo (ex: panela, frigideira).
@export var tool_id: String = "frigideira"

@onready var icon: TextureRect = $Icon


func _ready() -> void:
	## Evita capturar o clique no control pai
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	## Carrega ícone
	if icon:
		icon.texture = load("res://assets/utensilios/%s.png" % tool_id)


## Inicia o drag da ferramenta.
## NOTE: Não retorna `self` como source — retorna uma cópia não adicionada à árvore.
func _get_drag_data(_event_position: Vector2) -> Dictionary:
	if not icon.get_rect().has_point(_event_position):
		return {}

	# Cria uma instância 'source' que representa a unidade arrastada
	var source_instance: Control = self.duplicate() as Control
	source_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if source_instance is Tool:
		source_instance.tool_id = tool_id  # garante que herda o ID atual

	# Preview visual
	var preview: Control = source_instance.duplicate() as Control
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if preview is Tool:
		preview.tool_id = tool_id
	set_drag_preview(preview)

	DragManager.current_drag_type = DragManager.DragType.TOOL

	return {
		"id": tool_id,
		"state": "tool",
		"source": source_instance
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE
