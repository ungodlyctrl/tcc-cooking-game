extends Node2D
class_name MainScene

enum GameMode { ATTENDANCE, PREPARATION, END_OF_DAY }

# Modo de jogo atual
var current_mode: GameMode = GameMode.ATTENDANCE

# Tempo e economia
var current_time_minutes: int = 8 * 60
var day: int = 1
var money: int = 100
const END_OF_DAY_MINUTES := 19 * 60

# Dados do jogo
var region: String = "sudeste"
var current_recipe: RecipeResource

# Timer de relógio
var clock_timer: Timer = Timer.new()

# Referências da cena
@onready var mode_attendance: ModeAttendance = $Mode_Attendance
@onready var mode_preparation: Control = $Mode_Preparation
@onready var mode_end_of_day: Control = $Mode_EndOfDay
@onready var scroll_container: ScrollContainer = $Mode_Preparation/ScrollContainer
@onready var drop_plate_area: Control = $Mode_Preparation/ScrollContainer/PrepArea/DropPlateArea

# HUD
@onready var clock_label: Label = $HUD/ClockLabel
@onready var money_label: Label = $HUD/MoneyLabel
@onready var day_label: Label = $HUD/DayLabel


func _ready() -> void:
	# Inicializa relógio
	clock_timer.wait_time = 3.0
	clock_timer.timeout.connect(_on_time_tick)
	add_child(clock_timer)
	clock_timer.start()

	switch_mode(GameMode.ATTENDANCE)
	_update_ui()


func switch_mode(new_mode: GameMode) -> void:
	current_mode = new_mode

	mode_attendance.visible = new_mode == GameMode.ATTENDANCE
	mode_preparation.visible = new_mode == GameMode.PREPARATION
	mode_end_of_day.visible = new_mode == GameMode.END_OF_DAY
	$HUD.visible = new_mode != GameMode.END_OF_DAY

	if new_mode == GameMode.ATTENDANCE:
		load_new_recipe()
	elif new_mode == GameMode.PREPARATION:
		scroll_container.scroll_horizontal = 0


func _on_time_tick() -> void:
	current_time_minutes += 15

	if current_time_minutes >= END_OF_DAY_MINUTES:
		_end_day()

	_update_ui()


func _update_ui() -> void:
	var hours: int = current_time_minutes / 60
	var minutes: int = current_time_minutes % 60

	clock_label.text = "%02d:%02d" % [hours, minutes]
	money_label.text = "R$: " + str(money)
	day_label.text = "Dia " + str(day)


func _end_day() -> void:
	clock_timer.stop()
	switch_mode(GameMode.END_OF_DAY)


func start_new_day() -> void:
	day += 1
	current_time_minutes = 8 * 60
	clock_timer.start()
	switch_mode(GameMode.ATTENDANCE)
	_update_ui()


func add_money(amount: int) -> void:
	money += amount
	_update_ui()


func get_time_of_day() -> String:
	if current_time_minutes < 12 * 60:
		return "breakfast"
	elif current_time_minutes < 17 * 60:
		return "lunch"
	else:
		return "dinner"


func load_new_recipe() -> void:
	var time_of_day := get_time_of_day()
	current_recipe = RecipeManager.get_random_recipe(day, region, time_of_day)

	if current_recipe == null:
		push_warning("⚠️ Nenhuma receita encontrada para %s (%s, Dia %d)".format([region, time_of_day, day]))
		return

	current_recipe = current_recipe.apply_variations()  # <- aplica variações

	mode_attendance.set_recipe(current_recipe)
	$Mode_Attendance/DialogueBox.adjust_to_content()

	# Atualiza o painel da receita e a área de preparo
	$Mode_Preparation/HUDPrep/RecipePanel.show_recipe(current_recipe)
	drop_plate_area.set_current_recipe(current_recipe)

	show_random_client()


func show_random_client() -> void:
	if ClientManager.client_sprites.is_empty():
		push_warning("Nenhum sprite de cliente carregado!")
		return

	var client_sprite: Sprite2D = $Mode_Attendance/ClientSprite
	client_sprite.texture = ClientManager.client_sprites.pick_random()
	client_sprite.modulate = Color(1, 1, 1, 0)
	client_sprite.position = Vector2(165, 334)

	$Mode_Attendance/AnimationPlayer.play("client_entrance")
