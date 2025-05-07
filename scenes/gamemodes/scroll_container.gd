extends ScrollContainer

var dragging := false
var last_mouse_position := Vector2.ZERO

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			last_mouse_position = event.position
	elif event is InputEventMouseMotion and dragging:
		var delta = event.position - last_mouse_position
		scroll_horizontal -= delta.x
		last_mouse_position = event.position
