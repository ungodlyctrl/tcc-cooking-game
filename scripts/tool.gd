extends Control
class_name Tool

## Representa uma ferramenta de preparo (ex: panela, frigideira).
## Pode ser arrastada para o BurnerSlot ou outras áreas compatíveis.

# ---------------- Constants ----------------
const STATE_TOOL := "tool"

# 🔹 Offsets visuais personalizados para o preview de drag
const TOOL_DRAG_OFFSETS := {
	"panela": Vector2(-25, -15),
	"frigideira": Vector2(-24, -14)
}

# ---------------- Exports ----------------
@export var tool_id: String = "frigideira"

# ---------------- Onready ----------------
@onready var icon: TextureRect = $Icon


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if icon:
		icon.texture = load("res://assets/utensilios/%s.png" % tool_id)


func _get_drag_data(event_position: Vector2) -> Dictionary:
	if not icon.get_rect().has_point(event_position):
		return {}

	var source_instance: Tool = self.duplicate() as Tool
	source_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	source_instance.tool_id = tool_id

	# Cria preview com offset ajustado
	var preview := TextureRect.new()
	preview.texture = load("res://assets/utensilios/%s.png" % tool_id)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Aplica offset personalizado, se houver
	var offset : Vector2 = TOOL_DRAG_OFFSETS.get(tool_id, Vector2.ZERO)
	var wrapper := Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(preview)
	preview.position = offset

	set_drag_preview(wrapper)

	DragManager.current_drag_type = DragManager.DragType.TOOL

	return {
		"id": tool_id,
		"state": STATE_TOOL,
		"source": source_instance
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE
