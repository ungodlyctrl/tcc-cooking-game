extends Control
class_name ContainerSlot

@export var ingredient_id: String = "batata"
@onready var icon: TextureRect = $Icon


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var data: IngredientData = Managers.ingredient_database.get_ingredient(ingredient_id)
	if data and data.container_texture:
		icon.texture = data.container_texture

	if icon:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	connect("mouse_entered", Callable(self, "_on_slot_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_slot_mouse_exited"))


# ---------------------------------------------------------
# Drag & Drop
# ---------------------------------------------------------
func _get_drag_data(_pos: Vector2) -> Variant:
	AudioManager.play_sfx(AudioManager.library.ingredient_pick)
	var data: IngredientData = Managers.ingredient_database.get_ingredient(ingredient_id)
	if data == null:
		push_warning("⚠️ Ingrediente '%s' não encontrado no IngredientDatabase" % ingredient_id)
		return null

	var tt = _get_tooltip_node()
	if tt:
		tt.hide_tooltip()

	var start_state := data.initial_state

	# Cria a instância real do ingrediente (pra dropar depois)
	var ingredient_scene := preload("res://scenes/ui/ingredient.tscn")
	var ingredient: Ingredient = ingredient_scene.instantiate() as Ingredient
	ingredient.ingredient_id = ingredient_id
	ingredient.state = start_state
	ingredient._update_visual()
	ingredient.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 🔹 Busca o sprite correto do ingrediente no estado inicial
	var sprite_texture: Texture2D = Managers.ingredient_database.get_sprite(ingredient_id, start_state)

	# 🔹 Se não existir sprite, usa o ícone do container como fallback
	if sprite_texture == null:
		sprite_texture = icon.texture
		push_warning("⚠️ ContainerSlot: sprite não encontrado para '%s' (state: %s), usando ícone do container." % [ingredient_id, start_state])

	# 🔹 Cria o preview visual com suporte a offset customizado
	var preview := TextureRect.new()
	preview.texture = sprite_texture
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Se o ingrediente tiver offset configurado no IngredientData, aplicamos
	var offset := Vector2.ZERO
	if data and data.drag_offset != Vector2.ZERO:
		offset = data.drag_offset

	# Usamos um wrapper pra poder aplicar o offset visual
	var preview_wrapper := Control.new()
	preview_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_wrapper.add_child(preview)
	preview.position = offset

	set_drag_preview(preview_wrapper)

	# Cobra o custo do ingrediente (econômico)
	IngredientCostManager.charge_for_ingredient(get_tree().current_scene, ingredient_id)

	# Atualiza tipo no DragManager
	DragManager.current_drag_type = DragManager.DragType.INGREDIENT

	return {
		"id": ingredient_id,
		"state": start_state,
		"source": ingredient
	}


# ---------------------------------------------------------
# Tooltip helpers
# ---------------------------------------------------------
func _get_tooltip_node() -> Node:
	var scene_root := get_tree().current_scene
	if scene_root and scene_root.has_node("HUD/Tooltip"):
		return scene_root.get_node("HUD/Tooltip")
	return null


func _on_slot_mouse_entered() -> void:
	var data: IngredientData = Managers.ingredient_database.get_ingredient(ingredient_id)
	var name := data.display_name if data and data.display_name != "" else ingredient_id.capitalize()
	var tt := _get_tooltip_node()
	if tt:
		tt.show_tooltip(name, true)


func _on_slot_mouse_exited() -> void:
	var tt := _get_tooltip_node()
	if tt:
		tt.hide_tooltip()
