extends TextureRect

@export var ingredient_name := "massa"

func _ready():
	$Label.text = ingredient_name.capitalize()

func _get_drag_data(position):
	print("🎯 DRAG START:", ingredient_name)
	var preview = self.duplicate()
	DragManager.is_dragging_ingredient = true
	print("🟡 Início do drag!")
	set_drag_preview(preview)
	return ingredient_name
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	
func _drop_data(position, data):
	DragManager.is_dragging_ingredient = false
	print("🔵 Fim do drag!")
		
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		DragManager.is_dragging_ingredient = false  # backup se drop não for detectado
	
