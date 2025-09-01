extends TextureRect
class_name Ingredient

## Nó interativo que representa um ingrediente no jogo.
## Pode ser arrastado pela bancada e atualizado visualmente
## de acordo com seu estado (raw, cut, cooked, etc.).
##
## Esse script usa o banco de dados IngredientDatabase para
## carregar as informações do recurso IngredientData associado.

@export var ingredient_id: String
@export var state: String = "raw"  ## Estado inicial (ex: raw, cut, cooked, fried)
@export var is_cutting_result: bool = false  ## Se for resultado de minigame de corte

var original_position: Vector2
var data: IngredientData

@onready var label: Label = $Label


func _ready() -> void:
	## Configura o ingrediente ao ser instanciado
	add_to_group("day_temp")  ## grupo para facilitar limpeza no fim do dia
	data = IngredientDatabase.get_ingredient(ingredient_id)
	_update_visual()

	if is_cutting_result:
		## Guarda a posição para que o ingrediente volte se cair fora da tela
		original_position = position


func _update_visual() -> void:
	## Atualiza a aparência do ingrediente com base no estado atual
	if not data:
		return

	var tex: Texture2D = data.states.get(state, null)
	if tex:
		texture = tex

	label.text = data.display_name


func _get_drag_data(_pos: Vector2) -> Dictionary:
	## Inicia o processo de drag & drop.
	## Retorna um dicionário com os dados do ingrediente.
	var preview := self.duplicate()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)

	DragManager.current_drag_type = DragManager.DragType.INGREDIENT

	return {
		"id": ingredient_id,
		"state": state,
		"source": self  ## Importante para que outros scripts limpem a origem
	}


func _notification(what: int) -> void:
	## Reseta estado de drag ao fim do movimento.
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE

		## Caso seja um ingrediente de corte, se sair da tela volta para a posição original
		if is_cutting_result:
			await get_tree().process_frame
			if not get_global_rect().intersects(get_viewport_rect()):
				position = original_position
