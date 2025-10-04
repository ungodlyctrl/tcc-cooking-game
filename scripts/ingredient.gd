extends TextureRect 
class_name Ingredient

## Nó interativo que representa um ingrediente no jogo.
## Pode ser arrastado pela bancada e atualizado visualmente
## de acordo com seu estado (raw, cut, cooked, etc.).
## Usa Managers.ingredient_database para sprites/dados.

@export var ingredient_id: String
@export var state: String = "raw"  ## Estado inicial
@export var is_cutting_result: bool = false  ## Se for resultado de minigame de corte

var original_position: Vector2
var data: IngredientData

# preview manual adicionado ao gui_drag_overlay enquanto arrasta
var _overlay_preview: TextureRect = null

@onready var label: Label = $Label


func _ready() -> void:
	## Configura o ingrediente ao ser instanciado
	add_to_group("day_temp")  ## grupo para facilitar limpeza no fim do dia

	# usa Managers em vez de IngredientDatabase direto
	if Managers.ingredient_database:
		data = Managers.ingredient_database.get_ingredient(ingredient_id)
	else:
		push_error("❌ IngredientDatabase não inicializado!")
		data = null

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

	label.text = data.display_name if data.display_name != "" else ingredient_id.capitalize()


func _process(delta: float) -> void:
	# move preview overlay junto com mouse (se existir)
	if _overlay_preview and _overlay_preview.is_inside_tree():
		var mpos: Vector2 = get_viewport().get_mouse_position()
		var size: Vector2 = _overlay_preview.get_combined_minimum_size()
		_overlay_preview.global_position = mpos - (size / 2.0)


func _get_drag_data(_pos: Vector2) -> Dictionary:
	## Inicia o processo de drag & drop.
	## Criamos um preview manual no overlay para garantir que fique acima de tudo.

	var tex: Texture2D = null
	if Managers.ingredient_database:
		tex = Managers.ingredient_database.get_sprite(ingredient_id, state)

	var preview := TextureRect.new()
	if tex:
		preview.texture = tex

	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.name = "drag_preview_%s" % ingredient_id
	set_drag_preview(preview)
	# adiciona no overlay do viewport (topo) — cast explícito para Control


	DragManager.current_drag_type = DragManager.DragType.INGREDIENT

	return {
		"id": ingredient_id,
		"state": state,
		"source": self
	}


func _notification(what: int) -> void:
	## Reseta estado de drag ao fim do movimento.
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE

		## remove preview overlay se existir
		if _overlay_preview and _overlay_preview.is_inside_tree():
			_overlay_preview.queue_free()
		_overlay_preview = null
		set_process(false)

		## Caso seja um ingrediente de corte, se sair da tela volta para a posição original
		if is_cutting_result:
			await get_tree().process_frame
			if not get_global_rect().intersects(get_viewport_rect()):
				position = original_position
