extends Control
class_name IntroCutscene

@export var fade_time := 0.35
@export var delay_between_panels := 0.22
@export var group_hold_time := 0.7

@onready var group_a: Control = $PanelsGroupA
@onready var group_b: Control = $PanelsGroupB
@onready var skip_label: Label = $SkipLabel

var _skipped := false
var _blink_tween: Tween

signal cutscene_finished


func _ready() -> void:
	# tudo invisível no começo
	_set_group_alpha(group_a, 0.0)
	_set_group_alpha(group_b, 0.0)

	# label piscante
	_start_skip_blink()

	# iniciar cutscene
	_run_sequence()


# ================================================
#               SEQUÊNCIA PRINCIPAL
# ================================================
func _run_sequence() -> void:
	await get_tree().process_frame

	# -------- GRUPO A --------
	if not _skipped:
		await _show_panels_sequential(group_a)
		await get_tree().create_timer(group_hold_time).timeout

	if not _skipped:
		await _fade_out_group(group_a)

	# -------- GRUPO B --------
	if not _skipped:
		await _show_panels_sequential(group_b)
		await get_tree().create_timer(group_hold_time).timeout

	if not _skipped:
		await _fade_out_group(group_b)

	# finalizar
	_finish_cutscene()


# ================================================
#                EFFECT HELPERS
# ================================================
func _show_panels_sequential(group: Control) -> void:
	for child in group.get_children():
		if _skipped:
			return
		if child is TextureRect:
			child.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(child, "modulate:a", 1.0, fade_time)
			await tw.finished
			await get_tree().create_timer(delay_between_panels).timeout


func _fade_out_group(group: Control) -> void:
	var tw := create_tween().set_parallel(true)
	for child in group.get_children():
		if child is TextureRect:
			tw.tween_property(child, "modulate:a", 0.0, fade_time)
	await tw.finished


func _set_group_alpha(group: Control, value: float) -> void:
	for child in group.get_children():
		if child is TextureRect:
			child.modulate.a = value


# ================================================
#                SKIP SYSTEM
# ================================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_skip()
	if event is InputEventMouseButton and event.pressed:
		_skip()


func _skip() -> void:
	if _skipped:
		return
	_skipped = true

	# Para de piscar
	if _blink_tween:
		_blink_tween.kill()

	# Some tudo instantaneamente
	_set_group_alpha(group_a, 0.0)
	_set_group_alpha(group_b, 0.0)

	_finish_cutscene()


func _start_skip_blink() -> void:
	skip_label.modulate.a = 0.0
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(skip_label, "modulate:a", 0.7, 1.2)
	_blink_tween.tween_property(skip_label, "modulate:a", 0.2, 1.2)


# ================================================
#                FINALIZAÇÃO
# ================================================
func _finish_cutscene() -> void:
	emit_signal("cutscene_finished")
	queue_free()   # a cena é limpa; MainMenu faz a troca real
