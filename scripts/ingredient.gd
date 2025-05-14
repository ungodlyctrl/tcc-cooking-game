extends TextureRect
class_name Ingredient

## Componente de ingrediente interativo que pode ser arrastado pela bancada.
## Usa IngredientDatabase para definir o sprite e nome, baseado no estado atual (raw, cut, etc.).


@export var ingredient_id: String = "massa"
@export var state: String = "raw"  # Ex: "raw", "cut", "cooked", "fried", etc.
@export var is_cutting_result := false
var original_position: Vector2


func _ready() -> void:
	_update_visual()
	if is_cutting_result:
		original_position = position


## Atualiza a aparência visual com base no ingrediente e estado.
func _update_visual() -> void:
	var sprite_path := IngredientDatabase.get_sprite_path(ingredient_id, state)
	if sprite_path != "":
		texture = load(sprite_path)
	
	$Label.text = IngredientDatabase.get_display_name(ingredient_id, state)


## Inicia o processo de drag & drop ao clicar no ingrediente.
func _get_drag_data(_event_position: Vector2) -> Dictionary:
	var preview := self.duplicate()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)

	DragManager.current_drag_type = DragManager.DragType.INGREDIENT

	return {
		"id": ingredient_id,
		"state": state
	}


## Finaliza o drag & drop ao soltar o ingrediente.
func _drop_data(_event_position: Vector2, _data: Variant) -> void:
	DragManager.current_drag_type = DragManager.DragType.NONE


## Garante que o tipo de drag seja limpo mesmo que o drop falhe.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE
	if what == NOTIFICATION_DRAG_END and is_cutting_result:
		await get_tree().process_frame
		if not get_global_rect().intersects(get_viewport_rect()):
			position = original_position  # Volta para a tábua
		
