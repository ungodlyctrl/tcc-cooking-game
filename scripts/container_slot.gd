extends Control
class_name ContainerSlot

## Slot fixo na bancada que representa a fonte de um ingrediente.
## Quando arrastado, gera um novo `Ingredient` no estado inicial definido pelo IngredientData.

# --- Exportados ---
@export var ingredient_id: String = "batata"  ## ID do ingrediente definido no banco de dados

# --- Referências ---
@onready var icon: TextureRect = $Icon  ## Ícone exibido no slot


func _ready() -> void:
	## Ignorar eventos de mouse no container em si, apenas repassar para o drag.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	## Carrega os dados do ingrediente a partir do banco de dados.
	var data: IngredientData = IngredientDatabase.get_data(ingredient_id)
	if data and data.container_texture:
		icon.texture = data.container_texture


func _get_drag_data(event_position: Vector2) -> Dictionary:
	## Garante que o clique seja dentro do ícone do slot.
	if not icon.get_rect().has_point(event_position):
		return {}  

	## Pega os dados do ingrediente (com fallback).
	var data: IngredientData = IngredientDatabase.get_data(ingredient_id)
	if data == null:
		push_warning("⚠️ Ingrediente '%s' não encontrado no IngredientDatabase" % ingredient_id)
		return {}

	var start_state: String = data.initial_state

	## Instancia um `Ingredient` (prévia do drag).
	var preview: Ingredient = preload("res://scenes/ui/ingredient.tscn").instantiate() as Ingredient
	preview.ingredient_id = ingredient_id
	preview.state = start_state
	preview._update_visual()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	## Define a prévia do drag.
	set_drag_preview(preview)

	## Cobra o custo do ingrediente (econômico).
	IngredientCostManager.charge_for_ingredient(get_tree().current_scene, ingredient_id)

	## Atualiza o tipo de drag atual no DragManager.
	DragManager.current_drag_type = DragManager.DragType.INGREDIENT

	## Retorna o pacote de dados para o drop.
	return {
		"id": ingredient_id,
		"state": start_state,
		"source": self
	}
