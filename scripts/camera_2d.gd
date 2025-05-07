extends Camera2D

var dragging := false
var last_mouse_pos := Vector2.ZERO

func _ready():
	make_current()  # Ativa esta câmera como a principal

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		last_mouse_pos = event.position
	elif event is InputEventMouseMotion and dragging:
		var delta = event.position - last_mouse_pos
		global_position -= delta  # Move a câmera
		last_mouse_pos = event.position
