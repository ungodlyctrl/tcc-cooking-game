extends Control

@export var ingredient_name := "cenoura"  # será definido externamente

@onready var knife = $Knife
@onready var feedback = $FeedbackLabel
@onready var cut_lines = $CutLines
@onready var ingredient_sprite = $IngredientSprite

var total_cuts := 4
var current_cut_index := 0
var is_cutting := false
var ready_for_input := false

func _ready():
	ingredient_sprite.texture = load("res://assets/ingredientes/%s.png" % ingredient_name)
	_spawn_cut_lines()
	await get_tree().create_timer(0.3).timeout
	_start_cut_sequence()

func _spawn_cut_lines():
	for child in cut_lines.get_children():
		child.queue_free()
		
	for i in total_cuts:
		var line = Panel.new()
		line.custom_minimum_size = Vector2(10, 10)
		line.modulate = Color(1, 0, 0, 0.4)
		cut_lines.add_child(line)
		
func _start_cut_sequence():
	is_cutting = true
	current_cut_index = 0
	_move_knife_to_next_cut()
	
func _move_knife_to_next_cut():
	if current_cut_index >= cut_lines.get_child_count():
		is_cutting = false
		feedback.text = "✅ Corte finalizado!"
		await get_tree().create_timer(1.5).timeout
		queue_free()
		return

	var target = cut_lines.get_child(current_cut_index)

	# Pega a posição global do alvo
	var target_global_x = target.get_global_rect().position.x + target.size.x / 2
	# Corrige para posição local na CuttingBoard (Control)
	var local_x = target_global_x - self.get_global_rect().position.x - knife.size.x / 2

	knife.position = Vector2(local_x, 0)

	var tween = create_tween()
	tween.tween_property(knife, "position:y", 40, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(knife, "position:y", 0, 0.1)
	tween.tween_callback(Callable(self, "_on_knife_ready_for_input"))
	
func _on_knife_ready_for_input():
	ready_for_input = true
	feedback.text = "Clique para cortar!"
	
func _input(event):
	if ready_for_input and event is InputEventMouseButton and event.pressed:
		_check_cut()
		
func _check_cut():
	ready_for_input = false

	var knife_pos = knife.global_position.x
	var target = cut_lines.get_child(current_cut_index)
	var target_pos = target.global_position.x
	var tolerance = 20
	print("Knife X:", knife_pos, "Target X:", target_pos, "Diff:", abs(knife_pos - target_pos))

	if abs(knife_pos - target_pos) <= tolerance:
		feedback.text = "✅ Corte preciso!"
		target.modulate = Color(0, 1, 0, 0.6)  # Fica verde!
	else:
		feedback.text = "❌ Errou o corte!"
		target.modulate = Color(1, 0, 0, 0.8)

	current_cut_index += 1
	await get_tree().create_timer(0.6).timeout
	feedback.text = ""
	_move_knife_to_next_cut()
