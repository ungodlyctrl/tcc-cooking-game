extends TextureRect
class_name DropPlateArea

## Container de texto para ingredientes usados (pode ser opcional futuramente)
@onready var used_list: VBoxContainer = $VBoxContainer/UsedList

## Lista local dos ingredientes que foram colocados no prato
var used_ingredients: Array[String] = []


## Limpa os ingredientes usados e a UI do prato quando uma nova receita começa
func set_current_recipe(recipe: Resource) -> void:
	used_ingredients.clear()
	for child in used_list.get_children():
		child.queue_free()


## Aceita apenas ingredientes que não estão no estado "raw"
func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("id") or not data.has("state"):
		return false
	return data["state"] != "raw"


## Adiciona ingrediente ao prato (parte visual e lógica)
func _drop_data(_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_position, data):
		return

	var id: String = data["id"]
	used_ingredients.append(id)

	# Adiciona um rótulo com o nome do ingrediente (pode ser oculto futuramente)
	var label := Label.new()
	label.text = "- " + id.capitalize()
	used_list.add_child(label)

	print("Ingrediente adicionado ao prato:", id)
	
