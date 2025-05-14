extends Node2D 

@onready var mode_attendance = $Mode_Attendance
@onready var mode_preparation = $Mode_Preparation
@onready var mode_end_of_day = $Mode_EndOfDay
@onready var clock_label = $HUD/ClockLabel
@onready var money_label = $HUD/MoneyLabel
@onready var day_label = $HUD/DayLabel
@onready var drop_plate_area := $Mode_Preparation/ScrollContainer/PrepArea/DropPlateArea
@onready var scroll_container: ScrollContainer = $Mode_Preparation/ScrollContainer

enum GameMode { ATTENDANCE, PREPARATION, END_OF_DAY }

var current_mode = GameMode.ATTENDANCE
var current_recipe: Resource
var current_time_minutes := 8 * 60
var money := 100
var day := 1
var clock_timer := Timer.new()

func _ready():
	clock_timer.wait_time = 3.0
	clock_timer.timeout.connect(_on_time_tick)
	add_child(clock_timer)
	clock_timer.start()

	switch_mode(GameMode.ATTENDANCE)
	_update_ui()

func switch_mode(new_mode: GameMode):
	current_mode = new_mode

	$Mode_Attendance.visible = (new_mode == GameMode.ATTENDANCE)
	$Mode_Preparation.visible = (new_mode == GameMode.PREPARATION)
	$Mode_EndOfDay.visible = (new_mode == GameMode.END_OF_DAY)

	$HUD.visible = (new_mode != GameMode.END_OF_DAY)

	if new_mode == GameMode.ATTENDANCE:
		load_new_recipe() #nova receita
		
	if new_mode == GameMode.PREPARATION:
		scroll_container.scroll_horizontal = 0  # ⬅️ Reseta scroll

func _on_time_tick():
	current_time_minutes += 15
	if current_time_minutes >= (18 * 60):
		_end_day()
	_update_ui()

func _update_ui():
	var hours = current_time_minutes / 60
	var minutes = current_time_minutes % 60
	clock_label.text = "%02d:%02d" % [hours, minutes]
	money_label.text = "R$: " + str(money)
	day_label.text = "Dia " + str(day)

func _end_day():
	clock_timer.stop()
	switch_mode(GameMode.END_OF_DAY)
	
func start_new_day():
	day += 1
	current_time_minutes = 8 * 60 # 08:00 da manhã
	clock_timer.start()
	switch_mode(GameMode.ATTENDANCE)
	_update_ui()
	
func show_random_client():
	var client_sprites = [
		preload("res://assets/clients/client_1.png"),
		preload("res://assets/clients/client_2.png"),
		preload("res://assets/clients/client_3.png"),
		preload("res://assets/clients/client_4.png"),
		preload("res://assets/clients/client_5.png"),
		preload("res://assets/clients/client_6.png"),
	]

	var random_texture = client_sprites.pick_random()
	var client_sprite = $Mode_Attendance/ClientSprite
	client_sprite.texture = random_texture
	
	# Reset modulate and position to match animation start
	client_sprite.modulate = Color(1, 1, 1, 0)
	client_sprite.position = Vector2(165, 334)

	# Toca a animação de entrada
	$Mode_Attendance/AnimationPlayer.play("client_entrance")
	
func load_new_recipe(): 
	# Carrega uma receita (por enquanto sempre o pastel)
	current_recipe = RecipeLoader.get_random_recipe()
	
	show_random_client() # exibe um sprite de cliente aleatório

	# Pega uma fala aleatória da receita
	var random_line = current_recipe.dialog_lines.pick_random()

	# Atualiza o texto do DialogueBox
	$Mode_Attendance/DialogueBox/MarginContainer/RichTextLabel.text = random_line

	# Redimensiona o painel
	$Mode_Attendance/DialogueBox.adjust_to_content()
	
	# Mostrar o painel de receita
	$Mode_Preparation/HUDPrep/RecipePanel.show_recipe(current_recipe)
	
	drop_plate_area.set_current_recipe(current_recipe)
	
func add_money(amount: int) -> void:
	money += amount
	_update_ui()
