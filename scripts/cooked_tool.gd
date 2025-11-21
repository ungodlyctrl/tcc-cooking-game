extends Control
class_name CookedTool

const STATE_COOKED_TOOL := "cooked_tool"

const TOOL_DRAG_OFFSETS := {
	"panela": Vector2(-32, -16),
	"frigideira": Vector2(-24, -12)
}

@export var tool_type: String = ""
@export var cooked_ingredients: Array[Dictionary] = []

@onready var tool_sprite: TextureRect = $ToolSprite
@onready var mini_icons: HBoxContainer = $MiniIcons


func _ready() -> void:
	_load_tool_sprite()
	_refresh_mini_icons()
	add_to_group("day_temp")



func _load_tool_sprite() -> void:
	if tool_type == "":
		return
	var path := "res://assets/utensilios/%s.png" % tool_type
	tool_sprite.texture = load(path)



# ============================================================
# MINI ICONS
# ============================================================
func _refresh_mini_icons() -> void:
	for c in mini_icons.get_children():
		c.queue_free()

	for ing in cooked_ingredients:
		var id = ing.get("id", "")
		var st = ing.get("state", "")
		var tex = null

		if Managers and Managers.ingredient_database:
			tex = Managers.ingredient_database.get_mini_icon(id, st)

		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mini_icons.add_child(icon)



# ============================================================
# DRAG TOOL
# ============================================================
func _get_drag_data(_pos: Vector2) -> Dictionary:
	var preview_tex := load("res://assets/utensilios/%s.png" % tool_type)

	var preview := TextureRect.new()
	preview.texture = preview_tex
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var offset = TOOL_DRAG_OFFSETS.get(tool_type, Vector2.ZERO)

	var wrapper := Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(preview)
	preview.position = offset

	set_drag_preview(wrapper)

	tool_sprite.visible = false
	mini_icons.visible = false

	DragManager.current_drag_type = DragManager.DragType.TOOL

	return {
		"type": STATE_COOKED_TOOL,
		"tool_type": tool_type,
		"ingredients": cooked_ingredients,
		"source": self
	}



func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		DragManager.current_drag_type = DragManager.DragType.NONE

		tool_sprite.visible = true
		mini_icons.visible = true
