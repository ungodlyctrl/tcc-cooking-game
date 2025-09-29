extends Control
class_name DialogueBox

@export var typing_speed: float = 0.02
@export var confirm_delay: float = 0.3

@onready var ninepatch: NinePatchRect = $VBoxContainer/NinePatchRect
@onready var dialogue_label: RichTextLabel = $VBoxContainer/NinePatchRect/MarginContainer/DialogueLabel
@onready var next_button: Button = $VBoxContainer/HBoxContainer/NextButton
@onready var confirm_button: Button = $VBoxContainer/HBoxContainer/ConfirmButton

var lines: Array[String] = []
var current_index: int = 0
var _typing: bool = false
var _full_text: String = ""
var _full_pos: int = 0
var _typing_timer: Timer
var _delay_timer: Timer
var allow_confirm: bool = true  ## 🔥 controla se o botão confirmar pode aparecer

signal dialogue_confirmed

func _ready() -> void:
	dialogue_label.bbcode_enabled = true
	dialogue_label.text = ""
	next_button.pressed.connect(_on_next_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)

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

	dialogue_label.custom_minimum_size.x = 200
	dialogue_label.custom_minimum_size.y = 0

	_typing_timer.start()

	next_button.visible = false
	confirm_button.visible = false

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

func _on_confirm_button_pressed() -> void:
	emit_signal("dialogue_confirmed")

func hide_box() -> void:
	visible = false

func show_box() -> void:
	visible = true
