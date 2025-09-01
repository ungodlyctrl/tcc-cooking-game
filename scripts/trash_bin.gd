extends TextureRect
class_name TrashBin

## TrashBin (Lixeira)
## Responsável por receber e descartar objetos arrastados durante a preparação.
## - Ingredientes e utensílios podem ser descartados permanentemente.
## - Pratos (DropPlateArea) não são destruídos, mas seus ingredientes são removidos.

## Constantes para tipos aceitos no drop
const TYPE_COOKED_TOOL := "cooked_tool"
const TYPE_DELIVERED_PLATE := "delivered_plate"

## Texturas da lixeira
@export var closed_texture: Texture2D
@export var open_texture: Texture2D


func _ready() -> void:
	## Define estado inicial da lixeira (fechada)
	texture = closed_texture
	
	## Permite que este nó capture eventos de arrastar/soltar
	mouse_filter = Control.MOUSE_FILTER_PASS  


## Verifica se os dados soltos podem ser aceitos pela lixeira
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("type")


## Ação ao soltar dados sobre a lixeira
func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return

	var data_type: String = data["type"]

	# Caso seja uma ferramenta ou ingrediente processado
	if data_type == TYPE_COOKED_TOOL:
		var source: Control = data.get("source", null)
		if source and source.is_inside_tree():
			source.queue_free()

	# Caso seja um prato entregue
	elif data_type == TYPE_DELIVERED_PLATE:
		var source: Control = data.get("source", null)
		if source and source is DropPlateArea:
			# Em vez de chamar método "privado", ideal seria expor uma função pública em DropPlateArea
			source.clear_ingredients()


## Ao passar o mouse sobre a lixeira → abrir
func _on_mouse_entered() -> void:
	texture = open_texture


## Ao sair com o mouse da lixeira → fechar
func _on_mouse_exited() -> void:
	texture = closed_texture
