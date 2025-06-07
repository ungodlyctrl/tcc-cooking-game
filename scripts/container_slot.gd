extends Control
class_name ContainerSlot

## Slot de container para ingredientes na bancada.
## Exibe o sprite do container e inicia o drag de um ingrediente no estado "raw".


@export var ingredient_id: String = "batata"
@onready var icon: TextureRect = $Icon


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Carrega o sprite do container do ingrediente
	var sprite_path := IngredientDatabase.get_container_sprite(ingredient_id)
	if sprite_path != "":
		icon.texture = load(sprite_path)


## Retorna o dado de drag com o estado "raw" do ingrediente ao ser arrastado.
func _get_drag_data(_event_position: Vector2) -> Dictionary:
	if not icon.get_rect().has_point(_event_position):
		return {}  # Ignora clique fora do ícone
	
	# código original abaixo
	var preview := preload("res://scenes/ui/ingredient.tscn").instantiate()
	preview.ingredient_id = ingredient_id
	preview.state = "raw"
	preview._update_visual()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_drag_preview(preview)
	IngredientCostManager.charge_for_ingredient(get_tree().current_scene, ingredient_id)
	DragManager.current_drag_type = DragManager.DragType.INGREDIENT

	return {
		"id": ingredient_id,
		"state": "raw"
	}
