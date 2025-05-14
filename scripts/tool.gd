extends TextureRect
class_name Tool

## Representa uma ferramenta de preparo (ex: panela, frigideira).
## Pode ser arrastada para o fogão para iniciar o minigame de cozimento.
@export var tool_id: String = "frigideira"  # ou "panela"


## Inicia o drag da ferramenta, retornando os dados do tipo e estado.
func _get_drag_data(_event_position: Vector2) -> Dictionary:
	var preview := self.duplicate()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)

	DragManager.current_drag_type = DragManager.DragType.TOOL

	return {
		"id": tool_id,
		"state": "tool"
	}


## Garante que o estado do drag é limpo ao finalizar drop.
func _drop_data(_event_position: Vector2, _data) -> void:
	DragManager.current_drag_type = DragManager.DragType.NONE

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE
		get_tree().root.set_input_as_handled()
