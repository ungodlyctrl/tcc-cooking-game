extends TextureRect
class_name TopDeliveryArea

## Área de entrega de pratos
## - Mostra contorno piscante quando o jogador arrasta um prato
## - Entrega o prato ao soltar e muda o modo de jogo

@export var outline_color: Color = Color(1.0, 0.9, 0.3, 1.0)
@export var outline_thickness: float = 4.0
@export var outline_margin: float = 8.0
@export var blink_speed: float = 2.0
@export var always_visible_for_debug: bool = false

var _blink_time: float = 0.0
var _is_highlight_active: bool = false


# ---------------------- READY ----------------------
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # permite drop de prato
	z_index = 0  # mantém o contorno no nível certo
	set_process(true)


# ---------------------- PROCESS ----------------------
func _process(delta: float) -> void:
	_blink_time += delta
	var dragging_plate := _is_dragging_plate()

	if always_visible_for_debug:
		dragging_plate = true

	if dragging_plate != _is_highlight_active:
		_is_highlight_active = dragging_plate
		queue_redraw()
	elif _is_highlight_active:
		queue_redraw()


# ---------------------- DRAW ----------------------
func _draw() -> void:
	if not _is_highlight_active:
		return

	var blink := (sin(_blink_time * blink_speed * TAU) * 0.5 + 0.5)
	var alpha : Variant = clamp(0.1 + blink * 0.8, 0.0, 1.0)
	var col := Color(outline_color.r, outline_color.g, outline_color.b, alpha)

	var rect := Rect2(Vector2.ZERO - Vector2.ONE * outline_margin, size + Vector2.ONE * outline_margin * 2.0)
	draw_rect(rect, col, false, outline_thickness)


# ---------------------- DRAG DETECTION ----------------------
func _is_dragging_plate() -> bool:
	if typeof(DragManager) != TYPE_NIL:
		if DragManager.current_drag_type == DragManager.DragType.PLATE:
			return true

	var dm_node := get_node_or_null("/root/DragManager")
	if dm_node != null and dm_node.has_method("get"):
		var cur = dm_node.get("current_drag_type")
		if cur != null:
			return int(cur) == 3  # DragType.PLATE
	return false


# ---------------------- DROP LOGIC ----------------------
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "plate"


func _drop_data(_pos: Vector2, data: Variant) -> void:
	if not _can_drop_data(_pos, data):
		return

	_is_highlight_active = false
	queue_redraw()

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
