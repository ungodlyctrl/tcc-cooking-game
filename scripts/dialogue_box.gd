extends Control
class_name DialogueBox

@export var typing_speed: float = 0.02
@export var confirm_delay: float = 0.3

# ---------------------------------------------------------
# TEXTURAS DO BOTÃO DE CONFIRMAR
# ---------------------------------------------------------
@export var confirm_texture: Texture2D
@export var confirm_pressed_texture: Texture2D

# ---------------------------------------------------------
# TEXTURAS DO BOTÃO NEXT (FUNDO / BACKGROUND)
# ---------------------------------------------------------
@export var next_button_bg_normal: Texture2D
@export var next_button_bg_hover: Texture2D
@export var next_button_bg_pressed: Texture2D

# ---------------------------------------------------------
# TEXTURAS DA SETA DO BOTÃO NEXT
# ---------------------------------------------------------
@export var next_arrow_normal: Texture2D
@export var next_arrow_hover: Texture2D
@export var next_arrow_pressed: Texture2D

# ---------------------------------------------------------
# CORES
# ---------------------------------------------------------
@export var hover_text_color: Color = Color("f7a81f")
@export var pressed_text_color: Color = Color("#0f1735")
@export var tween_time: float = 0.08

# ---------------------------------------------------------
# NODES
# ---------------------------------------------------------
@onready var ninepatch: NinePatchRect = $VBoxContainer/NinePatchRect
@onready var dialogue_label: RichTextLabel = $VBoxContainer/NinePatchRect/MarginContainer/DialogueLabel
@onready var next_button: NinePatchRect = $VBoxContainer/HBoxContainer/NextButton
@onready var confirm_button: NinePatchRect = $VBoxContainer/HBoxContainer/ConfirmButton
@onready var confirm_label: Label = $VBoxContainer/HBoxContainer/ConfirmButton/Label
@onready var next_button_arrow: TextureRect = $VBoxContainer/HBoxContainer/NextButton/NextButtonArrow

# ---------------------------------------------------------
# VARIÁVEIS
# ---------------------------------------------------------
var lines: Array[String] = []
var current_index: int = 0
var _typing: bool = false
var _full_text: String = ""
var _full_pos: int = 0

var _typing_timer: Timer
var _delay_timer: Timer
var allow_confirm: bool = true

# ESTADOS INTERNOS
var _normal_font_color: Color
var _normal_confirm_texture: Texture2D
var _is_hovering: bool = false

var _next_bg_normal: Texture2D
var _next_arrow_normal: Texture2D


signal dialogue_confirmed


# =========================================================
# READY
# =========================================================
func _ready() -> void:
	dialogue_label.bbcode_enabled = true
	dialogue_label.text = ""

	_normal_font_color = confirm_label.get_theme_color("font_color")
	_normal_confirm_texture = confirm_button.texture

	# Salva texturas normais do botão NEXT
	_next_bg_normal = next_button_bg_normal
	_next_arrow_normal = next_arrow_normal

	# Conexões do NEXT BUTTON
	next_button.mouse_entered.connect(_on_next_hover_enter)
	next_button.mouse_exited.connect(_on_next_hover_exit)
	next_button.gui_input.connect(_on_next_button_gui_input)

	# Conexões do CONFIRM BUTTON
	confirm_button.gui_input.connect(_on_confirm_button_gui_input)
	confirm_button.mouse_entered.connect(_on_confirm_mouse_entered)
	confirm_button.mouse_exited.connect(_on_confirm_mouse_exited)

	# Criar timers
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



# =========================================================
# LINHAS / TEXTO
# =========================================================
func set_lines(new_lines: Array[String], can_confirm: bool = true) -> void:
	lines = new_lines.duplicate()
	current_index = 0
	allow_confirm = can_confirm
	_show_current_line()


func _show_current_line() -> void:
	if current_index >= lines.size():
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



func _on_show_confirm_button() -> void:
	if allow_confirm:
		confirm_button.visible = true
		_reset_confirm_visuals()



# =========================================================
# CONFIRM BUTTON (Hover)
# =========================================================
func _on_confirm_mouse_entered() -> void:
	_is_hovering = true
	confirm_label.add_theme_color_override("font_color", hover_text_color)


func _on_confirm_mouse_exited() -> void:
	_is_hovering = false
	confirm_label.add_theme_color_override("font_color", _normal_font_color)
	_restore_confirm_texture()



# =========================================================
# CONFIRM BUTTON (Press/Release)
# =========================================================
func _on_confirm_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:

		# PRESS
		if event.pressed:
			if confirm_pressed_texture:
				confirm_button.texture = confirm_pressed_texture

			confirm_label.add_theme_color_override("font_color", pressed_text_color)

		# RELEASE
		else:
			emit_signal("dialogue_confirmed")

			if _is_hovering:
				confirm_label.add_theme_color_override("font_color", hover_text_color)
			else:
				confirm_label.add_theme_color_override("font_color", _normal_font_color)

			_restore_confirm_texture()



func _restore_confirm_texture() -> void:
	if confirm_texture:
		confirm_button.texture = confirm_texture
	else:
		confirm_button.texture = _normal_confirm_texture


func _reset_confirm_visuals() -> void:
	# restaura cor
	confirm_label.add_theme_color_override("font_color", _normal_font_color)

	# restaura textura do botão confirmar
	if confirm_texture:
		confirm_button.texture = confirm_texture
	else:
		confirm_button.texture = _normal_confirm_texture

# =========================================================
# NEXT BUTTON (Hover / Exit)
# =========================================================
func _on_next_hover_enter() -> void:
	next_button_arrow.texture = next_arrow_hover
	if next_button_bg_hover:
		next_button.texture = next_button_bg_hover


func _on_next_hover_exit() -> void:
	next_button_arrow.texture = _next_arrow_normal
	next_button.texture = _next_bg_normal



# =========================================================
# NEXT BUTTON (Press/Release)
# =========================================================
func _on_next_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:

		# PRESS
		if event.pressed:
			if next_arrow_pressed:
				next_button_arrow.texture = next_arrow_pressed

			if next_button_bg_pressed:
				next_button.texture = next_button_bg_pressed

		# RELEASE
		else:
			# RESTAURAR correto dependendo do hover
			if next_button.get_rect().has_point(next_button.get_local_mouse_position()):
				next_button_arrow.texture = next_arrow_hover
				next_button.texture = next_button_bg_hover
			else:
				next_button_arrow.texture = next_arrow_normal
				next_button.texture = next_button_bg_normal

			# Lógica do diálogo
			if _typing:
				dialogue_label.text = _full_text
				_typing_timer.stop()
				_typing = false
				next_button.visible = true
			else:
				current_index += 1
				if current_index < lines.size():
					_show_current_line()



# =========================================================
# UTIL
# =========================================================
func hide_box() -> void:
	visible = false

func show_box() -> void:
	visible = true
