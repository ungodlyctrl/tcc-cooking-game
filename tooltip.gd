extends Control

@onready var label: Label = $Label
@onready var background: NinePatchRect = $Label/Background

var _visible_follow := false
const MOUSE_OFFSET := Vector2(8, 8)
const PADDING := Vector2(4, 1) # margem interna do background

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = false
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func show_tooltip(text: String, follow_mouse: bool = true) -> void:
	label.text = text
	_update_background_size()
	visible = true
	_visible_follow = follow_mouse
	_update_position()

func hide_tooltip() -> void:
	visible = false
	_visible_follow = false

func show_at(text: String, global_pos: Vector2) -> void:
	label.text = text
	_update_background_size()
	visible = true
	_visible_follow = false
	_set_global_position_clamped(global_pos + MOUSE_OFFSET)

func _process(_dt: float) -> void:
	if visible and _visible_follow:
		_update_position()

func _update_position() -> void:
	var mpos := get_viewport().get_mouse_position()
	_set_global_position_clamped(mpos + MOUSE_OFFSET)

func _set_global_position_clamped(global_pos: Vector2) -> void:
	position = global_pos
	var vp_size: Vector2 = get_viewport_rect().size
	var tip_size: Vector2 = size
	position.x = clamp(position.x, 4.0, vp_size.x - tip_size.x - 4.0)
	position.y = clamp(position.y, 4.0, vp_size.y - tip_size.y - 4.0)

func _update_background_size() -> void:
	await get_tree().process_frame # garante que o texto foi atualizado antes

	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")

	# mede o texto renderizado
	var text_size := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	background.size = text_size + PADDING * 2
	background.position = -PADDING
