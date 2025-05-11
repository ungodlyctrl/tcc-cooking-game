extends Control

@export var ingredient_name := "cenoura"

@onready var ingredient_sprite = $IngredientSprite
@onready var pointer = $QTEBar/Pointer
@onready var zones = [$QTEBar/Hitzone1, $QTEBar/Hitzone2, $QTEBar/Hitzone3]
@onready var knife = $Knife
@onready var feedback = $FeedbackLabel

var pointer_speed := 80  # pixels por segundo (ajuste conforme necessário)
var max_time := 4.0  # tempo total de movimento
var hit_registered := false
var score := 0
var attempts := 3  # número de tentativas permitidas

func _ready():
	ingredient_sprite.texture = load("res://assets/ingredientes/%s.png" % ingredient_name)
	pointer.position.x = 0
	knife.modulate.a = 0
	feedback.text = ""
	set_process(true)
	print("Pointer:", pointer)
	print("Knife:", knife)
	print("Zones:", zones)

func _process(delta):
	if hit_registered:
		return
	
	pointer.position.x += pointer_speed * delta

	if pointer.position.x >= $QTEBar.size.x:
		end_qte()

func _input(event):
	if event is InputEventMouseButton and event.pressed and not hit_registered:
		_attempt_cut()

func _attempt_cut():
	attempts -= 1
	var pointer_x = pointer.position.x
	
	var success = false
	for zone in zones:
		var zone_start = zone.position.x
		var zone_end = zone.position.x + zone.size.x
		if pointer_x >= zone_start and pointer_x <= zone_end:
			success = true
			zone.modulate = Color(0.0, 1.0, 0.0, 0.7)  # muda para verde forte
			score += 1
			break

	feedback.text = "✅ Corte bom!" if success else "❌ Fora da zona"
	_show_knife_effect()
	
	if attempts <= 0:
		end_qte()

func _show_knife_effect():
	var ingredient_pos = ingredient_sprite.position
	var ingredient_width = ingredient_sprite.size.x
	var offset_y = -15  # ajuste de altura visual

	var section_index = clamp(3 - attempts, 0, 2)
	var sections = [0.2, 0.4, 0.65]  # início, meio, fim

	# Calcula a posição base do corte
	var cut_x = ingredient_pos.x + (ingredient_width * sections[section_index]) - knife.size.x / 2
	var cut_y = ingredient_pos.y + offset_y

	var cut_pos = Vector2(cut_x, cut_y)
	knife.position = cut_pos
	knife.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_property(knife, "position", cut_pos + Vector2(6, 20), 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(knife, "modulate:a", 0.0, 0.1).set_delay(0.1)

	await tween.finished

func end_qte():
	hit_registered = true
	feedback.text += "\nPontuação: %d/3" % score
	await get_tree().create_timer(1.5).timeout
	# Aqui você pode emitir sinal para o sistema principal usar a pontuação
	queue_free()
