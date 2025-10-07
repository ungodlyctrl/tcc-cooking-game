extends Control

@onready var label: Label = $Label
@onready var background: NinePatchRect = $Background

var _visible_follow := false
const MOUSE_OFFSET := Vector2(10, 10)

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_OFF

func show_tooltip(text: String, follow_mouse: bool = true) -> void:
	label.text = text
	visible = true
	_visible_follow = follow_mouse
	_update_position()

func hide_tooltip() -> void:
	visible = false
	_visible_follow = false

func show_at(text: String, global_pos: Vector2) -> void:
	label.text = text
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
	# Define posição global do tooltip (assumindo que está em um CanvasLayer fixo ou HUD)
	position = global_pos

	# Evita que o tooltip saia da tela
	var vp_size: Vector2 = get_viewport_rect().size
	var tip_size: Vector2 = size

	position.x = clamp(position.x, 4.0, vp_size.x - tip_size.x - 4.0)
	position.y = clamp(position.y, 4.0, vp_size.y - tip_size.y - 4.0)
