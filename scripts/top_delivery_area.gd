extends TextureRect
class_name TopDeliveryArea

## Exibe um contorno piscante (anel oco/duplo) quando o jogador está arrastando um PRATO.

@onready var outline_effect: ColorRect = $OutlineEffect
@onready var shader_mat: ShaderMaterial = null

var _is_highlight_active: bool = false


func _ready() -> void:
	# material pode estar no ColorRect ou no próprio TextureRect: preferimos no OutlineEffect
	if outline_effect:
		shader_mat = outline_effect.material if outline_effect.material is ShaderMaterial else null
	if not shader_mat:
		push_error("❌ TopDeliveryArea: ShaderMaterial não encontrado no OutlineEffect. O highlight não funcionará.")
	else:
		shader_mat.set_shader_parameter("show_outline", false)
	_print_ready()


func _print_ready() -> void:
	print("🟢 TopDeliveryArea pronto. OutlineEffect:", outline_effect != null, " Shader:", shader_mat != null)


func _process(_delta: float) -> void:
	if shader_mat == null:
		return

	var dragging_plate := false

	if typeof(DragManager) != TYPE_NIL and "current_drag_type" in DragManager:
		dragging_plate = DragManager.current_drag_type == DragManager.DragType.PLATE

	if dragging_plate and not _is_highlight_active:
		print("✨ Highlight ativado (drag de prato).")
		_enable_highlight(true)
	elif not dragging_plate and _is_highlight_active:
		print("✨ Highlight desativado.")
		_enable_highlight(false)



func _enable_highlight(enable: bool) -> void:
	_is_highlight_active = enable
	if shader_mat == null:
		return
	shader_mat.set_shader_parameter("show_outline", enable)
	# opcional — log pra debug
	if enable:
		print("🌟 TopDeliveryArea: outline ON")
	else:
		print("💤 TopDeliveryArea: outline OFF")


# ---------------------- DROP ----------------------
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "plate"


func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return

	_enable_highlight(false)

	var delivered_plate := preload("res://scenes/ui/delivered_plate.tscn").instantiate()
	delivered_plate.ingredients = data["ingredients"]

	var main := get_tree().current_scene
	if main and main.current_recipe and main.current_recipe.delivered_plate_sprite:
		delivered_plate.plate_texture = main.current_recipe.delivered_plate_sprite
	else:
		delivered_plate.plate_texture = preload("res://assets/prato2.png")

	var source_node: Control = data.get("source", null)
	if source_node and source_node is DropPlateArea:
		source_node.clear_ingredients()

	main.switch_mode(main.GameMode.ATTENDANCE)
	main.call_deferred("_spawn_delivered_plate", delivered_plate)
	main.mode_attendance.dialogue_box.hide_box()
