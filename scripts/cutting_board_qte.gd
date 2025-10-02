extends Control
class_name CuttingBoardQTE

signal finished_cut(ingredient_id: String, hits: int)

const POINTER_SPEED: float = 80.0
const KNIFE_SECTIONS: Array[float] = [0.2, 0.4, 0.65]
const KNIFE_OFFSET_Y: float = -15.0

@export var ingredient_name: String = ""

var board_area: CuttingBoardArea = null
var attempts: int = 3
var score: int = 0
var hit_registered: bool = false

@onready var ingredient_sprite: TextureRect = $IngredientSprite
@onready var pointer: TextureRect = $QTEBar/Pointer
@onready var zones: Array[Control] = [$QTEBar/Hitzone1, $QTEBar/Hitzone2, $QTEBar/Hitzone3]
@onready var knife: TextureRect = $CanvasLayer/Knife2
@onready var feedback: Label = $FeedbackLabel


func _ready() -> void:
	var tex: Texture2D = Managers.ingredient_database.get_sprite(ingredient_name, "raw")
	if tex:
		ingredient_sprite.texture = tex
	else:
		push_error("❌ Sprite não encontrado para: %s (raw)" % ingredient_name)

	knife.texture = preload("res://assets/Faca de ladinho.png")
	pointer.position.x = 0
	knife.modulate.a = 0
	feedback.text = ""
	set_process(true)


func _process(delta: float) -> void:
	if hit_registered:
		return

	pointer.position.x += POINTER_SPEED * delta
	var bar_width: float = $QTEBar.size.x
	var pointer_width: float = pointer.size.x

	if pointer.position.x + pointer_width >= bar_width:
		pointer.position.x = bar_width - pointer_width
		end_qte()


func _input(event: InputEvent) -> void:
	if not is_cooking():
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

	if success:
		feedback.text = "Corte bom!"
	else:
		feedback.text = "Fora da zona"

	_show_knife_effect()

	if attempts <= 0:
		end_qte()


func _show_knife_effect() -> void:
	var section_index: int = clamp(3 - attempts, 0, 2)
	var ingredient_pos: Vector2 = ingredient_sprite.get_global_position()
	var knife_start: Vector2 = Vector2(
		ingredient_pos.x + ingredient_sprite.size.x * KNIFE_SECTIONS[section_index] - knife.size.x / 2,
		ingredient_pos.y + KNIFE_OFFSET_Y
	)

	knife.visible = true
	knife.modulate.a = 1.0
	knife.position = knife_start
	knife.z_index = 100

	var tween: Tween = create_tween()
	tween.tween_property(knife, "position", knife_start + Vector2(6, 6), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(knife, "modulate:a", 0.0, 0.08).set_delay(0.08)

	await tween.finished


func end_qte() -> void:
	set_process(false)
	hit_registered = true

	match score:
		3: feedback.text = "Perfeito!"
		2: feedback.text = "Bom!"
		1: feedback.text = "Razoável"
		_: feedback.text = "Ruim"

	await get_tree().create_timer(1.0).timeout
	_spawn_cut_ingredient()

	emit_signal("finished_cut", ingredient_name, score)

	var bancada_knife: Node = $ScrollContainer/PrepArea/UtensilsParent/CuttingBoardArea/BancadaKnife
	if bancada_knife:
		bancada_knife.visible = true

	queue_free()


func _spawn_cut_ingredient() -> void:
	var ingredient: Node = preload("res://scenes/ui/ingredient.tscn").instantiate()
	ingredient.ingredient_id = ingredient_name
	ingredient.state = "cut"
	ingredient.is_cutting_result = true
	ingredient.set_meta("qte_hits", score)

	if board_area and board_area.is_inside_tree():
		board_area.add_child(ingredient)
		var board_size: Vector2 = board_area.size
		var ing_size: Vector2 = ingredient.size
		ingredient.position = (board_size / 2.0) - (ing_size / 2.0)

		if board_area.has_method("notify_result_placed"):
			board_area.notify_result_placed(ingredient)

		ingredient.tree_exited.connect(func():
			if board_area.has_method("notify_ingredient_removed"):
				board_area.notify_ingredient_removed())
