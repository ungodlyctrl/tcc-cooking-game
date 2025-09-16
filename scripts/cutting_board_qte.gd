extends Control
class_name CuttingBoardQTE

## Minigame de corte (QTE - Quick Time Event).
## O jogador precisa acertar zonas na barra para cortar bem o ingrediente.
## No fim, um ingrediente no estado "cut" é gerado e colocado na CuttingBoardArea.


# ---------------- Constants ----------------
const POINTER_SPEED: float = 80.0           ## Velocidade que o ponteiro percorre a barra
const KNIFE_SECTIONS: Array[float] = [0.2, 0.4, 0.65]  ## Posições relativas de cortes
const KNIFE_OFFSET_Y: float = -15.0         ## Ajuste vertical da faca


# ---------------- Exports ----------------
@export var ingredient_name: String = ""    ## Ingrediente em preparo (ex: "cenoura")


# ---------------- Vars ----------------
var board_area: CuttingBoardArea = null     ## Referência à área da tábua
var attempts: int = 3                       ## Número de tentativas
var score: int = 0                          ## Quantidade de acertos
var hit_registered: bool = false            ## Marca se já terminou


# ---------------- Onready ----------------
@onready var ingredient_sprite: TextureRect = $IngredientSprite
@onready var pointer: TextureRect = $QTEBar/Pointer
@onready var zones: Array[Control] = [$QTEBar/Hitzone1, $QTEBar/Hitzone2, $QTEBar/Hitzone3]
@onready var knife: TextureRect = $CanvasLayer/Knife2
@onready var feedback: Label = $FeedbackLabel


# ---------------- Lifecycle ----------------
func _ready() -> void:
	## Carrega sprite do ingrediente cru
	var tex: Texture2D = IngredientDatabase.get_sprite(ingredient_name, "raw")
	if tex == null:
		push_error("❌ Sprite não encontrado para: %s (raw)" % ingredient_name)
	else:
		ingredient_sprite.texture = tex

	## Config inicial
	knife.texture = preload("res://assets/Faca de ladinho.png")
	pointer.position.x = 0
	knife.modulate.a = 0
	feedback.text = ""
	set_process(true)


func _process(delta: float) -> void:
	if hit_registered:
		return

	## Avança ponteiro
	pointer.position.x += POINTER_SPEED * delta
	var bar_width: float = $QTEBar.size.x
	var pointer_width: float = pointer.size.x

	## Se chegou ao fim, encerra
	if pointer.position.x + pointer_width >= bar_width:
		pointer.position.x = bar_width - pointer_width
		end_qte()


func _input(event: InputEvent) -> void:
	if not is_cooking():
		return
	if event is InputEventMouseButton and event.pressed:
		_attempt_cut()


# ---------------- Core Logic ----------------
func is_cooking() -> bool:
	return not hit_registered and attempts > 0


func _attempt_cut() -> void:
	attempts -= 1
	var pointer_x: float = pointer.position.x
	var success: bool = false

	# Checa se o clique aconteceu dentro de alguma zona válida
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
	## Mostra animação da faca em cima do ingrediente
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

	## Avalia resultado
	var result_text: String = ""
	match score:
		3: result_text = "Perfeito!"
		2: result_text = "Bom!"
		1: result_text = "Razoável"
		_: result_text = "Ruim"
	feedback.text = result_text

	## Espera e gera ingrediente cortado
	await get_tree().create_timer(1.0).timeout
	_spawn_cut_ingredient()

	## Restaura faca da bancada
	var bancada_knife: Node = $"../BancadaKnife"
	if bancada_knife:
		bancada_knife.visible = true

	queue_free()


func _spawn_cut_ingredient() -> void:
	## Cria ingrediente cortado
	var ingredient: Node = preload("res://scenes/ui/ingredient.tscn").instantiate()
	ingredient.ingredient_id = ingredient_name
	ingredient.state = "cut"
	ingredient.is_cutting_result = true
	ingredient.set_meta("qte_hits", score)

	if board_area and board_area.is_inside_tree():
		board_area.add_child(ingredient)

		## Centraliza na tábua
		var board_size: Vector2 = board_area.size
		var ing_size: Vector2 = ingredient.size
		ingredient.position = (board_size / 2.0) - (ing_size / 2.0)

		## Notifica área da tábua
		if board_area.has_method("notify_result_placed"):
			board_area.notify_result_placed(ingredient)

		ingredient.tree_exited.connect(func():
			if board_area.has_method("notify_ingredient_removed"):
				board_area.notify_ingredient_removed())
