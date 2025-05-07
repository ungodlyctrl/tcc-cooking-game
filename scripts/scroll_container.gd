extends ScrollContainer

var dragging := false
var last_mouse_pos := Vector2.ZERO

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			last_mouse_pos = event.position
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		var delta = event.relative
		scroll_horizontal -= delta.x
		
