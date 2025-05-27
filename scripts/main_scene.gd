extends Node2D
class_name MainScene

# Enums para definir os modos de jogo
enum GameMode { ATTENDANCE, PREPARATION, END_OF_DAY }

# Nodes principais
@onready var mode_attendance: Control = $Mode_Attendance
@onready var mode_preparation: Control = $Mode_Preparation
@onready var mode_end_of_day: Control = $Mode_EndOfDay
@onready var scroll_container: ScrollContainer = $Mode_Preparation/ScrollContainer
@onready var drop_plate_area: Control = $Mode_Preparation/ScrollContainer/PrepArea/DropPlateArea

# HUD
@onready var clock_label: Label = $HUD/ClockLabel
@onready var money_label: Label = $HUD/MoneyLabel
@onready var day_label: Label = $HUD/DayLabel

# Tempo e economia
var current_time_minutes: int = 8 * 60
var day: int = 1
var money: int = 100
const END_OF_DAY_MINUTES := 18 * 60  # 18h

# Estado do jogo
var current_mode: GameMode = GameMode.ATTENDANCE
var current_recipe: Resource = null

# Timer para o relógio do jogo
var clock_timer: Timer = Timer.new()

# Lista de texturas de cliente (carregadas automaticamente)
var client_sprites: Array[Texture2D] = []


func _ready() -> void:
	# Inicia o timer do relógio
	clock_timer.wait_time = 3.0
	clock_timer.timeout.connect(_on_time_tick)
	add_child(clock_timer)
	clock_timer.start()
	

	# Define o modo inicial
	switch_mode(GameMode.ATTENDANCE)
	_update_ui()


# Troca de modo (Atendimento, Preparo, Fim de dia)
func switch_mode(new_mode: GameMode) -> void:
	current_mode = new_mode

	mode_attendance.visible = new_mode == GameMode.ATTENDANCE
	mode_preparation.visible = new_mode == GameMode.PREPARATION
	mode_end_of_day.visible = new_mode == GameMode.END_OF_DAY

	$HUD.visible = new_mode != GameMode.END_OF_DAY

	if new_mode == GameMode.ATTENDANCE:
		load_new_recipe()

	elif new_mode == GameMode.PREPARATION:
		scroll_container.scroll_horizontal = 0  # Reinicia scroll horizontal


# Tick do tempo de jogo (15 min a cada ciclo)
func _on_time_tick() -> void:
	current_time_minutes += 15

	if current_time_minutes >= END_OF_DAY_MINUTES:
		_end_day()

	_update_ui()


# Atualiza elementos da HUD
func _update_ui() -> void:
	var hours := current_time_minutes / 60
	var minutes := current_time_minutes % 60

	clock_label.text = "%02d:%02d" % [hours, minutes]
	money_label.text = "R$: " + str(money)
	day_label.text = "Dia " + str(day)


# Finaliza o dia
func _end_day() -> void:
	clock_timer.stop()
	switch_mode(GameMode.END_OF_DAY)


# Reinicia o ciclo no próximo dia
func start_new_day() -> void:
	day += 1
	current_time_minutes = 8 * 60
	clock_timer.start()
	switch_mode(GameMode.ATTENDANCE)
	_update_ui()


# Adiciona dinheiro ao jogador
func add_money(amount: int) -> void:
	money += amount
	_update_ui()


# Carrega uma nova receita e mostra cliente aleatório
func load_new_recipe() -> void:
	current_recipe = RecipeLoader.get_random_recipe()

	show_random_client()

	var random_line: String = current_recipe.dialog_lines.pick_random()
	$Mode_Attendance/DialogueBox/MarginContainer/RichTextLabel.text = random_line
	$Mode_Attendance/DialogueBox.adjust_to_content()

	$Mode_Preparation/HUDPrep/RecipePanel.show_recipe(current_recipe)
	drop_plate_area.set_current_recipe(current_recipe)


# Mostra um sprite de cliente aleatório com animação
func show_random_client() -> void:
	if ClientManager.client_sprites.is_empty():
		push_warning("Nenhum cliente disponível!")
		return

	var client_sprite := $Mode_Attendance/ClientSprite
	client_sprite.texture = ClientManager.client_sprites.pick_random()
	client_sprite.modulate = Color(1, 1, 1, 0)
	client_sprite.position = Vector2(165, 334)

	$Mode_Attendance/AnimationPlayer.play("client_entrance")
