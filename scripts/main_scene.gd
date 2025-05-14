extends Node2D
class_name MainScene


# Referências aos modos de jogo e elementos da HUD
@onready var mode_attendance = %Mode_Attendance
@onready var mode_preparation = %Mode_Preparation
@onready var mode_end_of_day = %Mode_EndOfDay

@onready var clock_label = %ClockLabel
@onready var money_label = %MoneyLabel
@onready var day_label = %DayLabel
@onready var drop_area = %DropArea
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var client_sprite = %ClientSprite
@onready var dialogue_label = %DialogueLabel
@onready var recipe_panel = %RecipePanel
@onready var client_anim = %AnimationPlayer


# Estados do jogo
enum GameMode { ATTENDANCE, PREPARATION, END_OF_DAY }

var current_mode = GameMode.ATTENDANCE
var current_recipe: Resource
var current_time_minutes := 8 * 60  # Começa às 8:00
var money := 100
var day := 1

var clock_timer := Timer.new()


# Inicialização
func _ready():
	clock_timer.wait_time = 3.0
	clock_timer.timeout.connect(_on_time_tick)
	add_child(clock_timer)
	clock_timer.start()

	switch_mode(GameMode.ATTENDANCE)
	_update_ui()


# Troca de modo de jogo (atendimento, preparo, fim de dia)
func switch_mode(new_mode: GameMode):
	current_mode = new_mode

	mode_attendance.visible = (new_mode == GameMode.ATTENDANCE)
	mode_preparation.visible = (new_mode == GameMode.PREPARATION)
	mode_end_of_day.visible = (new_mode == GameMode.END_OF_DAY)

	%HUD.visible = (new_mode != GameMode.END_OF_DAY)

	if new_mode == GameMode.ATTENDANCE:
		load_new_recipe()

	if new_mode == GameMode.PREPARATION:
		scroll_container.scroll_horizontal = 0  # Reset scroll


# Atualização do relógio e UI
func _on_time_tick():
	current_time_minutes += 15

	if current_time_minutes >= 18 * 60:
		_end_day()

	_update_ui()


func _update_ui():
	var hours = current_time_minutes / 60
	var minutes = current_time_minutes % 60

	clock_label.text = "%02d:%02d" % [hours, minutes]
	money_label.text = "R$: " + str(money)
	day_label.text = "Dia " + str(day)


# Controle de dia
func _end_day():
	clock_timer.stop()
	switch_mode(GameMode.END_OF_DAY)


func start_new_day():
	day += 1
	current_time_minutes = 8 * 60
	clock_timer.start()
	switch_mode(GameMode.ATTENDANCE)
	_update_ui()


# Carregamento de cliente aleatório
func show_random_client():
	var client_textures: Array = []

	var dir = DirAccess.open("res://assets/clients")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png"):
				var path = "res://assets/clients/" + file_name
				client_textures.append(load(path))
			file_name = dir.get_next()
		dir.list_dir_end()

	if client_textures.size() > 0:
		var random_texture = client_textures.pick_random()
		client_sprite.texture = random_texture

	client_sprite.modulate = Color(1, 1, 1, 0)
	client_sprite.position = Vector2(165, 334)
	client_anim.play("client_entrance")


# ─────────────────────────────────────────────────────────────
# Carregamento de receita
# ─────────────────────────────────────────────────────────────
func load_new_recipe():
	current_recipe = RecipeLoader.get_random_recipe()
	show_random_client()

	var random_line = current_recipe.dialog_lines.pick_random()
	dialogue_label.text = random_line

	%DialogueBox.adjust_to_content()
	recipe_panel.show_recipe(current_recipe)
	drop_area.set_current_recipe(current_recipe)


# ─────────────────────────────────────────────────────────────
# Ganhar dinheiro após pedido
# ─────────────────────────────────────────────────────────────
func add_money(amount: int) -> void:
	money += amount
	_update_ui()
