extends Control
class_name DialogueBox

@export var typing_speed: float = 0.02
@export var confirm_delay: float = 0.3

# Texturas do botão (arraste no inspector)
@export var confirm_texture: Texture2D
@export var confirm_pressed_texture: Texture2D

# Cores
@export var hover_text_color: Color = Color("f7a81f")
@export var pressed_text_color: Color = Color("#0f1735") # opcional
@export var tween_time: float = 0.08

@onready var ninepatch: NinePatchRect = $VBoxContainer/NinePatchRect
@onready var dialogue_label: RichTextLabel = $VBoxContainer/NinePatchRect/MarginContainer/DialogueLabel
@onready var next_button: Button = $VBoxContainer/HBoxContainer/NextButton
@onready var confirm_button: NinePatchRect = $VBoxContainer/HBoxContainer/ConfirmButton
@onready var confirm_label: Label = $VBoxContainer/HBoxContainer/ConfirmButton/Label

var lines: Array[String] = []
var current_index: int = 0
var _typing: bool = false
var _full_text: String = ""
var _full_pos: int = 0
var _typing_timer: Timer
var _delay_timer: Timer
var allow_confirm: bool = true

# internal state
var _normal_font_color: Color
var _normal_button_texture: Texture2D = null
var _is_hovering: bool = false

signal dialogue_confirmed


func _ready() -> void:
	dialogue_label.bbcode_enabled = true
	dialogue_label.text = ""

	# salva cor original da fonte
	_normal_font_color = confirm_label.get_theme_color("font_color")

	# salva textura original
	_normal_button_texture = confirm_button.texture

	# next button
	next_button.pressed.connect(_on_next_button_pressed)

	# input do botão
	confirm_button.gui_input.connect(_on_confirm_button_gui_input)
	confirm_button.mouse_entered.connect(_on_confirm_mouse_entered)
	confirm_button.mouse_exited.connect(_on_confirm_mouse_exited)

	# timers
	_typing_timer = Timer.new()
	_typing_timer.wait_time = typing_speed
	_typing_timer.one_shot = false
	add_child(_typing_timer)
	_typing_timer.timeout.connect(_on_type_next_char)

	_delay_timer = Timer.new()
	_delay_timer.one_shot = true
	add_child(_delay_timer)
	_delay_timer.timeout.connect(_on_show_confirm_button)

	next_button.visible = false
	confirm_button.visible = false


func set_lines(new_lines: Array[String], can_confirm: bool = true) -> void:
	lines = new_lines.duplicate()
	current_index = 0
	allow_confirm = can_confirm
	_show_current_line()


func _show_current_line() -> void:
	if current_index < 0 or current_index >= lines.size():
		return

	_full_text = lines[current_index]
	_full_pos = 0
	dialogue_label.text = ""
	_typing = true

	dialogue_label.custom_minimum_size = Vector2(200, 0)

	_typing_timer.start()

	next_button.visible = false
	confirm_button.visible = false

	_reset_confirm_visuals()


func _on_type_next_char() -> void:
	if _full_pos >= _full_text.length():
		_typing_timer.stop()
		_typing = false

		if current_index < lines.size() - 1:
			next_button.visible = true
		elif allow_confirm:
			_delay_timer.start(confirm_delay)
		return

	dialogue_label.text += _full_text[_full_pos]
	_full_pos += 1

	var text_size = dialogue_label.get_combined_minimum_size()
	ninepatch.custom_minimum_size = text_size + Vector2(12, 16)


func _on_next_button_pressed() -> void:
	if _typing:
		dialogue_label.text = _full_text
		_typing_timer.stop()
		_typing = false
		next_button.visible = true
	else:
		current_index += 1
		if current_index < lines.size():
			_show_current_line()


func _on_show_confirm_button() -> void:
	if allow_confirm:
		confirm_button.visible = true
		_reset_confirm_visuals()


# --------------------------
# HOVER
# --------------------------

func _on_confirm_mouse_entered() -> void:
	_is_hovering = true

	var tw = create_tween()
	tw.tween_callback(func():
		confirm_label.add_theme_color_override("font_color", hover_text_color)
	)


func _on_confirm_mouse_exited() -> void:
	_is_hovering = false

	var tw = create_tween()
	tw.tween_callback(func():
		confirm_label.add_theme_color_override("font_color", _normal_font_color)
	)

	_restore_texture()


# --------------------------
# PRESS / RELEASE
# --------------------------

func _on_confirm_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# pressed texture
			if confirm_pressed_texture:
				confirm_button.texture = confirm_pressed_texture

			confirm_label.add_theme_color_override("font_color", pressed_text_color)

		else:
			# release → emitir sinal
			emit_signal("dialogue_confirmed")

			# volta visual dependendo se ainda está hover
			if _is_hovering:
				confirm_label.add_theme_color_override("font_color", hover_text_color)
			else:
				confirm_label.add_theme_color_override("font_color", _normal_font_color)

			_restore_texture()


func _restore_texture() -> void:
	if confirm_texture:
		confirm_button.texture = confirm_texture
	else:
		confirm_button.texture = _normal_button_texture


func _reset_confirm_visuals() -> void:
	confirm_label.add_theme_color_override("font_color", _normal_font_color)
	_restore_texture()


# --------------------------
# Utilitários
# --------------------------
func hide_box() -> void:
	visible = false

func show_box() -> void:
	visible = true
