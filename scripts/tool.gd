extends TextureRect

@export var tool_id := "frigideira"  # ou "panela"

func _get_drag_data(position):
	var preview = self.duplicate()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)

	DragManager.current_drag_type = DragManager.DragType.TOOL

	return {
		"id": tool_id,
		"state": "tool"
	}

func _drop_data(position, data):
	DragManager.current_drag_type = DragManager.DragType.NONE

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		DragManager.current_drag_type = DragManager.DragType.NONE
