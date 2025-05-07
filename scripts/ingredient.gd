extends TextureRect

@export var ingredient_name := "massa"

func _ready():
	$Label.text = ingredient_name.capitalize()

func _get_drag_data(position):
	print("🎯 DRAG START:", ingredient_name)
	var preview = self.duplicate()
	set_drag_preview(preview)
	return ingredient_name
	
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			DragManager.is_dragging_ingredient = true
		else:
			DragManager.is_dragging_ingredient = false
