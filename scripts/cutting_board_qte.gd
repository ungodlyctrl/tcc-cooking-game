extends Control
class_name CuttingBoardQTE

@export var ingredient_name: String = "cenoura"

@onready var ingredient_sprite: TextureRect = $IngredientSprite
@onready var pointer: TextureRect = $QTEBar/Pointer
@onready var zones: Array[Control] = [$QTEBar/Hitzone1, $QTEBar/Hitzone2, $QTEBar/Hitzone3]
@onready var knife: TextureRect = $Knife
@onready var feedback: Label = $FeedbackLabel

# Referência à área da tábua, usada para posicionar o ingrediente cortado corretamente
var board_area: Node = null

# Configurações do minigame
const POINTER_SPEED: float = 80.0
const KNIFE_SECTIONS: Array[float] = [0.2, 0.4, 0.65]
const KNIFE_OFFSET_Y: float = -15.0

var attempts: int = 3
var score: int = 0
var hit_registered: bool = false


func _ready() -> void:
	var tex_path: String = IngredientDatabase.get_sprite_path(ingredient_name, "raw")
	if tex_path == "":
		push_error("❌ Sprite não encontrado para: %s (raw)" % ingredient_name)
	else:
		ingredient_sprite.texture = load(tex_path)

	pointer.position.x = 0
	knife.modulate.a = 0
	feedback.text = ""
	set_process(true)


func _process(delta: float) -> void:
	if hit_registered:
		return

	pointer.position.x += POINTER_SPEED * delta

	if pointer.position.x >= $QTEBar.size.x:
		end_qte()


func _input(event: InputEvent) -> void:
	if not is_instance_valid(event) or not is_cooking():
		return

	if event is InputEventMouseButton and event.pressed:
		_attempt_cut()


func is_cooking() -> bool:
	return not hit_registered and attempts > 0


func _attempt_cut() -> void:
	attempts -= 1
	var pointer_x: float = pointer.position.x
	var success: bool = false

	for zone in zones:
		var zone_start: float = zone.position.x
		var zone_end: float = zone_start + zone.size.x

		if pointer_x >= zone_start and pointer_x <= zone_end:
			success = true
			zone.modulate = Color(0.0, 1.0, 0.0, 0.7)
			score += 1
			break

	feedback.text = "Corte bom!" if success else "Fora da zona"
	_show_knife_effect()

	if attempts <= 0:
		end_qte()


func _show_knife_effect() -> void:
	var section_index: int = clamp(3 - attempts, 0, 2)
	var ingredient_pos: Vector2 = ingredient_sprite.position
	var ingredient_width: float = ingredient_sprite.size.x

	var base_x: float = ingredient_pos.x + (ingredient_width * KNIFE_SECTIONS[section_index]) - knife.size.x / 2
	var cut_y: float = ingredient_pos.y + KNIFE_OFFSET_Y
	var cut_pos: Vector2 = Vector2(base_x, cut_y)

	knife.position = cut_pos
	knife.modulate.a = 1.0

	var tween: Tween = create_tween()
	tween.tween_property(knife, "position", cut_pos + Vector2(6, 20), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(knife, "modulate:a", 0.0, 0.1).set_delay(0.1)

	await tween.finished


func end_qte() -> void:
	set_process(false)

	var result_text: String = ""
	match score:
		3: result_text = "Perfeito!"
		2: result_text = "Bom!"
		1: result_text = "Razoável"
		_: result_text = "Ruim"

	feedback.text = result_text
	await get_tree().create_timer(1.0).timeout
	_spawn_cut_ingredient()
	queue_free()


func _spawn_cut_ingredient() -> void:
	var ingredient: Node = preload("res://scenes/ui/ingredient.tscn").instantiate()
	ingredient.ingredient_id = ingredient_name
	ingredient.state = "cut"
	ingredient.is_cutting_result = true

	if board_area and board_area.is_inside_tree():
		board_area.add_child(ingredient)

		# Posiciona centralizado na tábua (parente da área de corte)
		var board_global: Vector2 = board_area.get_global_position()
		var parent_global: Vector2 = board_area.get_parent().get_global_position()
		var local_pos: Vector2 = board_global - parent_global

		ingredient.position = local_pos

		if board_area.has_method("notify_result_placed"):
			board_area.notify_result_placed(ingredient)
