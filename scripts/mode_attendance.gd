extends Control
class_name ModeAttendance

@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var client_sprite: Sprite2D = $ClientSprite
@onready var map_hint: TextureRect = $MapHintOutline   # ⭐ novo outline piscando (pode ser null em algumas cenas)
@onready var map_button: Node = $MapinhaRoxo           # botão do mapa (pode ser null)

var current_recipe: RecipeResource
var has_shown_map_hint: bool = false   # ⭐ só mostra 1 vez por sessão
var _hint_tween: Tween = null

# estado do background (para transições suaves)
var current_background_set: CityBackgroundSet = null
var current_bg_time: String = ""
var _bg_tween: Tween = null

func _ready() -> void:
	# conectar diálogo
	if dialogue_box:
		dialogue_box.dialogue_confirmed.connect(_on_confirm_button_pressed)

	# garante invisível até o momento certo (checa nulo)
	if map_hint:
		map_hint.visible = false
		map_hint.modulate.a = 0.0

	# se houver botão, garantir que recebe input (opcional)
	if map_button:
		map_button.mouse_filter = Control.MOUSE_FILTER_STOP
		# caso o botão não esteja conectado via editor, conecte aqui
		if not map_button.is_connected("gui_input", Callable(self, "_on_mapinha_roxo_gui_input")):
			map_button.gui_input.connect(_on_mapinha_roxo_gui_input)


func set_recipe(recipe: RecipeResource, client_lines: Array[String] = []) -> void:
	current_recipe = recipe

	var lines: Array[String] = []
	if not client_lines.is_empty():
		lines = client_lines.duplicate()
	elif not recipe.client_lines.is_empty():
		lines.append(recipe.client_lines.pick_random())
	else:
		lines.append("...")

	if dialogue_box:
		dialogue_box.show_box()
		dialogue_box.set_lines(lines, true)


# ============================================================
# ⭐⭐ HINT DO MAPA → chamado pela MainScene todos os dias ⭐⭐
# ============================================================
func show_map_hint_if_needed(day: int) -> void:
	if has_shown_map_hint:
		return
	if day < 4:
		return
	if map_hint == null:
		return

	# mostra outline
	map_hint.visible = true

	if _hint_tween:
		_hint_tween.kill()

	_hint_tween = create_tween()
	_hint_tween.set_loops()  # piscar infinito até clicar
	_hint_tween.tween_property(map_hint, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	_hint_tween.tween_property(map_hint, "modulate:a", 0.2, 0.45).set_trans(Tween.TRANS_SINE)


# ============================================================
# Quando clicar no mapa → PARA de piscar para sempre
# ============================================================
func _stop_map_hint() -> void:
	has_shown_map_hint = true

	if _hint_tween:
		_hint_tween.kill()
		_hint_tween = null

	if map_hint:
		map_hint.visible = false


func _on_mapinha_roxo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_sfx(AudioManager.library.ui_click)
		_stop_map_hint()  # ⭐ para a animação
		var main := get_tree().current_scene as MainScene
		if main:
			main.open_region_map()


func _on_confirm_button_pressed() -> void:
	var main_scene = get_tree().current_scene as MainScene
	if main_scene:
		main_scene.prep_start_minutes = main_scene.current_time_minutes
		main_scene.switch_mode(MainScene.GameMode.PREPARATION)


func show_client(client: ClientData) -> void:
	if client == null:
		return

	AudioManager.play_sfx(AudioManager.library.new_client)
	if client_sprite:
		client_sprite.texture = client.neutral
		client_sprite.visible = true
		client_sprite.modulate = Color(1, 1, 1, 0)
		client_sprite.position = Vector2(165, 334)
	$AnimationPlayer.play("client_entrance")


func show_feedback(text: String, grade: String, client: ClientData) -> void:
	if client != null:
		match grade:
			"Excelente", "Bom":
				AudioManager.play_sfx(AudioManager.library.good_reaction)
				if client_sprite:
					client_sprite.texture = client.happy if client.happy != null else client.neutral
			"Ruim":
				AudioManager.play_sfx(AudioManager.library.bad_reaction)
				if client_sprite:
					client_sprite.texture = client.angry if client.angry != null else client.neutral
			_:
				if client_sprite:
					client_sprite.texture = client.neutral

	if dialogue_box:
		dialogue_box.show_box()
		dialogue_box.set_lines([text], false)


func hide_client() -> void:
	$AnimationPlayer.play("client_exit")
	await $AnimationPlayer.animation_finished
	if $ClientSprite:
		$ClientSprite.visible = false

	var main = get_tree().current_scene as MainScene
	if main:
		main.load_new_recipe()


# ===================== BACKGROUNDS =====================
# Estrutura esperada:
# current_background_set é um resource que tem propriedades:
#   .morning (Texture2D), .afternoon (Texture2D), .night (Texture2D)
# Você deve atribuir current_background_set antes (ex: ao setar região).
#
# update_city_background faz um cross-fade suave entre a textura atual e a nova.
func update_city_background(time_of_day: String) -> void:
	# se não tem set de backgrounds, tenta pegar do dicionário antigo (compatibilidade)
	if current_background_set == null:
		return

	# escolher textura do conjunto
	var new_tex: Texture2D = null
	match time_of_day:
		"morning":
			new_tex = current_background_set.morning
		"afternoon":
			new_tex = current_background_set.afternoon
		"night":
			new_tex = current_background_set.night
		_:
			new_tex = null

	if new_tex == null:
		return

	# Se for o mesmo horário, não troca
	if time_of_day == current_bg_time:
		return

	current_bg_time = time_of_day

	var bg := $CityBackground
	if bg == null:
		return

	# cria uma TextureRect temporária (igual ao bg) para fazer o fade-in
	var fade_rect := TextureRect.new()
	fade_rect.texture = new_tex
	# copiar layout/size/position do bg para garantir encaixe
	
	fade_rect.modulate.a = 0.0
	# garantir mesma stretch/expand se bg usa
	if bg is TextureRect:
		fade_rect.stretch_mode = bg.stretch_mode
	# adicionar sobre o mesmo parent
	if bg.get_parent():
		bg.get_parent().add_child(fade_rect)
	else:
		add_child(fade_rect)

	# tween suave
	if _bg_tween:
		_bg_tween.kill()
	_bg_tween = create_tween()
	_bg_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await _bg_tween.finished

	# troca a textura real e remove o temporário
	bg.texture = new_tex
	if fade_rect.is_inside_tree():
		fade_rect.queue_free()


# Helper: aplicar textura sem transição (fallback)
func _set_background_immediate(tex: Texture2D) -> void:
	var bg := $CityBackground
	if bg and tex:
		bg.texture = tex
		current_bg_time = ""


# Para compatibilidade com o antigo dicionário usado antes da refatoração
var time_backgrounds := {
	"morning": preload("res://assets/backgrounds/city_morning.png"),
	"afternoon": preload("res://assets/backgrounds/city_afternoon.png"),
	"night": preload("res://assets/backgrounds/city_night.png")
}
