extends Control
class_name ModeAttendance

@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var client_sprite: Sprite2D = $ClientSprite
@onready var map_hint: TextureRect = $MapHintOutline
@onready var map_button: Control = $MapinhaRoxo
@onready var city_bg: TextureRect = $CityBackground   # <- AGR VAI RECEBER A TEXTURA DIRETO

var current_background_set: CityBackgroundSet = null  # set do dia (SP, Rio, Nordeste...)
var current_bg_time: String = ""                      # morning / afternoon / night

var current_recipe: RecipeResource
var has_shown_map_hint := false
var _hint_tween: Tween = null

func _ready() -> void:
	# Conecta diálogo
	if dialogue_box:
		dialogue_box.dialogue_confirmed.connect(_on_confirm_button_pressed)

	# Map hint invisível
	if map_hint:
		map_hint.visible = false
		map_hint.modulate.a = 0.0

	# Botão do mapa
	if map_button:
		map_button.mouse_filter = Control.MOUSE_FILTER_STOP
		if not map_button.is_connected("gui_input", Callable(self, "_on_mapinha_roxo_gui_input")):
			map_button.gui_input.connect(_on_mapinha_roxo_gui_input)

	# garante que não exista shader antigo
	if city_bg:
		city_bg.material = null


func set_recipe(recipe: RecipeResource, client_lines: Array[String] = []) -> void:
	current_recipe = recipe

	var lines: Array[String] = []
	if not client_lines.is_empty():
		lines = client_lines.duplicate()
	elif recipe and not recipe.client_lines.is_empty():
		lines.append(recipe.client_lines.pick_random())
	else:
		lines.append("...")

	if dialogue_box:
		dialogue_box.show_box()
		dialogue_box.set_lines(lines, true)


# ============================================================
# MAP HINT
# ============================================================
func show_map_hint_if_needed(day: int) -> void:
	if has_shown_map_hint: return
	if day < 4: return
	if map_hint == null: return

	map_hint.visible = true

	if _hint_tween:
		_hint_tween.kill()

	_hint_tween = create_tween()
	_hint_tween.set_loops()
	_hint_tween.tween_property(map_hint, "modulate:a", 1.0, 0.45)
	_hint_tween.tween_property(map_hint, "modulate:a", 0.2, 0.45)


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
		_stop_map_hint()

		var main := get_tree().current_scene as MainScene
		if main:
			main.open_region_map()


func _on_confirm_button_pressed() -> void:
	var main_scene = get_tree().current_scene as MainScene
	if main_scene:
		main_scene.prep_start_minutes = main_scene.current_time_minutes
		main_scene.switch_mode(MainScene.GameMode.PREPARATION)


# ============================================================
# CLIENTE
# ============================================================
func show_client(client: ClientData) -> void:
	if client == null:
		return

	AudioManager.play_sfx(AudioManager.library.new_client)
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
				client_sprite.texture = client.happy if client.happy else client.neutral
			"Ruim":
				AudioManager.play_sfx(AudioManager.library.bad_reaction)
				client_sprite.texture = client.angry if client.angry else client.neutral
			_:
				client_sprite.texture = client.neutral

	dialogue_box.show_box()
	dialogue_box.set_lines([text], false)


func hide_client() -> void:
	$AnimationPlayer.play("client_exit")
	await $AnimationPlayer.animation_finished
	client_sprite.visible = false

	var main = get_tree().current_scene as MainScene
	if main:
		main.load_new_recipe()


# ============================================================
# BACKGROUND (SECO, SEM FADE)
# ============================================================
func update_city_background(time_of_day: String) -> void:
	if current_background_set == null:
		return

	var tex: Texture2D = null

	match time_of_day:
		"morning": tex = current_background_set.morning
		"afternoon": tex = current_background_set.afternoon
		"night": tex = current_background_set.night

	if tex == null:
		return

	current_bg_time = time_of_day

	# 🌄 troca direta sem transição
	if city_bg:
		city_bg.texture = tex
