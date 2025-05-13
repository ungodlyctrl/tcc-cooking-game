extends TextureRect

@export var ingredient_id := "massa"
@export var state := "raw"  # Estados possíveis: "raw", "cut", "cooked", etc.

func _ready():
	print("🔍 IngredientDatabase:", IngredientDatabase)
	print("🍠 Path batata crua:", IngredientDatabase.get_sprite_path("batata", "raw"))
	_update_visual()

func _update_visual():
	var path = IngredientDatabase.get_sprite_path(ingredient_id, state)
	if path != "":
		texture = load(path)
	$Label.text = IngredientDatabase.get_display_name(ingredient_id, state)

func _get_drag_data(position):
	print("🎯 DRAG START:", ingredient_id, " (", state, ")")
	var preview = self.duplicate()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)

	DragManager.current_drag_type = DragManager.DragType.INGREDIENT
	print("🟡 Início do drag!")

	return {
		"id": ingredient_id,
		"state": state
	}

func _drop_data(position, data):
	DragManager.current_drag_type = DragManager.DragType.NONE

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		DragManager.current_drag_type = DragManager.DragType.NONE
