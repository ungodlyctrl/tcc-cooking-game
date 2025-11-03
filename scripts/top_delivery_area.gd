extends TextureRect
class_name TopDeliveryArea

## Exibe um contorno piscante (anel oco) em volta da área de entrega
## quando o jogador está arrastando um prato.

@export var outline_color: Color = Color(1.0, 0.9, 0.3, 1.0)
@export var outline_thickness: float = 4.0        # pixels
@export var outline_margin: float = 8.0           # pixels de afastamento
@export var blink_speed: float = 2.0              # velocidade da piscada

var _is_highlight_active: bool = false
var _blink_time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = max(z_index, 10)
	print("🟢 TopDeliveryArea pronto.")
	_enable_highlight(true)


func _process(delta: float) -> void:
	_blink_time += delta

	var dragging_plate := _is_dragging_plate()

	if dragging_plate and not _is_highlight_active:
		_enable_highlight(true)
	elif not dragging_plate and _is_highlight_active:
		_enable_highlight(false)

	if _is_highlight_active:
		queue_redraw()


func _is_dragging_plate() -> bool:
	# Tenta acessar via Managers primeiro
	if Managers != null and Managers.drag_manager != null:
		return Managers.drag_manager.current_drag_type == Managers.drag_manager.DragType.PLATE

	# fallback — tenta autoload direto
	if typeof(DragManager) != TYPE_NIL:
		return DragManager.current_drag_type == DragManager.DragType.PLATE

	# fallback extremo — busca nó na árvore
	var dm: Node = get_node_or_null("/root/DragManager")
	if dm != null and dm.has_method("get"):
		var cur: Variant = dm.get("current_drag_type")
		if cur != null:
			return int(cur) == 3

	return false


func _enable_highlight(enable: bool) -> void:
	_is_highlight_active = enable
	if enable:
		print("🌟 Outline ON")
	else:
		print("💤 Outline OFF")


func _draw() -> void:
	if not _is_highlight_active:
		return

	var blink := (sin(_blink_time * blink_speed * TAU) * 0.5 + 0.5)
	var alpha :Variant = clamp(0.2 + blink * 0.8, 0.0, 1.0)
	var col: Color = Color(outline_color.r, outline_color.g, outline_color.b, alpha)

	var rect := Rect2(
		-Vector2.ONE * outline_margin,
		size + Vector2.ONE * outline_margin * 2.0
	)

	draw_rect(rect, col, false, outline_thickness)


# ---------------------- DROP ----------------------
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY \
		and data.has("type") \
		and data["type"] == "plate"


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

	if main:
		main.switch_mode(main.GameMode.ATTENDANCE)
		main.call_deferred("_spawn_delivered_plate", delivered_plate)
		if main.mode_attendance and main.mode_attendance.dialogue_box:
			main.mode_attendance.dialogue_box.hide_box()
