extends Control

@export var ingredient_id: String = "batata"
@onready var icon := $Icon

func _ready():
	var sprite_path = IngredientDatabase.get_container_sprite(ingredient_id)
	icon.texture = load(sprite_path)

func _get_drag_data(position):
	var preview = preload("res://scenes/ui/ingredient.tscn").instantiate()
	preview.ingredient_id = ingredient_id
	preview.state = "raw"
	preview._update_visual()  # Garante que o visual é atualizado antes do drag

	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)

	DragManager.current_drag_type = DragManager.DragType.INGREDIENT

	print("🚚 Drag de", ingredient_id, "state: raw")

	return {
		"id": ingredient_id,
		"state": "raw"
	}
