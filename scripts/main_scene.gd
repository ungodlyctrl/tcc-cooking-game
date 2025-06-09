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
var last_time_of_day := ""

# Dados do jogo
var region: String = "sudeste"
var current_recipe: RecipeResource
var prep_start_minutes: int = -1
var pending_delivery: Array[Dictionary] = []
# Lista com os relatórios dos pedidos feitos no dia
var daily_report: Array = []
var total_ingredient_expense : int = 0

# Timer de relógio
var clock_timer: Timer = Timer.new()

# Referências da cena
@onready var mode_attendance: ModeAttendance = $Mode_Attendance
@onready var mode_preparation: Control = $Mode_Preparation
@onready var mode_end_of_day: Control = $Mode_EndOfDay
@onready var scroll_container: ScrollContainer = $Mode_Preparation/ScrollContainer
@onready var drop_plate_parent: Node = $Mode_Preparation/ScrollContainer/PrepArea
@onready var drop_plate_scene: PackedScene = preload("res://scenes/ui/drop_plate_area.tscn")
var drop_plate_area: Control

# HUD
@onready var clock_label: Label = $HUD/ClockLabel
@onready var money_label: Label = $HUD/MoneyLabel
@onready var day_label: Label = $HUD/DayLabel


func _ready() -> void:
	# Inicializa relógio
	clock_timer.wait_time = 2.0
	clock_timer.timeout.connect(_on_time_tick)
	add_child(clock_timer)
	clock_timer.start()

	switch_mode(GameMode.ATTENDANCE)
	_update_ui()
	load_new_recipe()
	last_time_of_day = get_visual_time_of_day()
	mode_attendance.update_city_background(last_time_of_day)

func switch_mode(new_mode: GameMode) -> void:
	current_mode = new_mode

	mode_attendance.visible = new_mode == GameMode.ATTENDANCE
	mode_preparation.visible = new_mode == GameMode.PREPARATION
	mode_end_of_day.visible = new_mode == GameMode.END_OF_DAY
	$HUD.visible = new_mode != GameMode.END_OF_DAY
	
	$Mode_Preparation/HUDPrep/RecipeNotePanel.hide()

	if new_mode == GameMode.PREPARATION:
		scroll_container.scroll_horizontal = 0

var day_should_end: bool = false

func _on_time_tick() -> void:
	current_time_minutes += 15

	if current_time_minutes >= END_OF_DAY_MINUTES:
		day_should_end = true

	_update_ui()
	
	if current_mode == GameMode.PREPARATION:
		update_score_display()
	
	var visual_time := get_visual_time_of_day()
	if visual_time != last_time_of_day:
		last_time_of_day = visual_time
		mode_attendance.update_city_background(visual_time)


func _update_ui() -> void:
	var hours: int = current_time_minutes / 60
	var minutes: int = current_time_minutes % 60

	clock_label.text = "%02d:%02d" % [hours, minutes]
	money_label.text = "M$: " + str(money)
	day_label.text = "Dia " + str(day)
	
	if current_time_minutes >= END_OF_DAY_MINUTES and not (current_mode == GameMode.END_OF_DAY):
		clock_label.add_theme_color_override("font_color", Color.RED)
	else:
		clock_label.remove_theme_color_override("font_color")


func _end_day() -> void:
	clock_timer.stop()
	populate_end_of_day_report()
	switch_mode(GameMode.END_OF_DAY)


func start_new_day() -> void:
	day += 1
	current_time_minutes = 8 * 60
	day_should_end = false  # <- MUITO IMPORTANTE
	prep_start_minutes = -1
	daily_report.clear()
	total_ingredient_expense = 0
	pending_delivery.clear()
	last_time_of_day = get_visual_time_of_day()
	mode_attendance.update_city_background(last_time_of_day)

	# Remove qualquer prato anterior
	if drop_plate_area and drop_plate_area.is_inside_tree():
		drop_plate_area.queue_free()
	drop_plate_area = null

	# Limpa bancada/ferramentas (garanta que o método exista, corrigimos isso abaixo)
	var prep_area := $Mode_Preparation/ScrollContainer/PrepArea
	if prep_area.has_method("clear_day_leftovers"):
		prep_area.clear_day_leftovers()

	clock_timer.start()
	switch_mode(GameMode.ATTENDANCE)
	load_new_recipe()
	_update_ui()
	var score_label: Label = $HUD/HBoxContainer/ScoreLabel
	score_label.text = "100%"
	
	


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


func get_visual_time_of_day() -> String:
	if current_time_minutes < 16 * 60:
		return "morning"
	elif current_time_minutes < 18 * 60:
		return "afternoon"
	else:
		return "night"


func update_score_display(optional_score: int = -1) -> void:
	var score_label: Label = $HUD/HBoxContainer/ScoreLabel

	if optional_score >= 0:
		score_label.text = "%d%%" % optional_score
		return

	if current_recipe == null or prep_start_minutes < 0:
		return

	var elapsed_minutes := current_time_minutes - prep_start_minutes
	var time_penalty := int(elapsed_minutes / 15)  # 1 ponto a cada 15 minutos do jogo

	var score := 100 - time_penalty
	score = clamp(score, 0, 100)

	score_label.text = "%d%%" % score


func load_new_recipe() -> void:
	var time_of_day := get_time_of_day()
	current_recipe = RecipeManager.get_random_recipe(day, region, time_of_day)

	if current_recipe == null:
		push_warning("⚠️ Nenhuma receita encontrada para %s (%s, Dia %d)".format([region, time_of_day, day]))
		return

	current_recipe = current_recipe.apply_variations()  # <- aplica variações
	prep_start_minutes = current_time_minutes

	mode_attendance.set_recipe(current_recipe)
	$Mode_Attendance/DialogueBox.adjust_to_content()
	var score_label: Label = $HUD/HBoxContainer/ScoreLabel
	score_label.text = "100%"
	prep_start_minutes = -1

	# Atualiza o painel da receita e a área de preparo
	mode_preparation.set_recipe(current_recipe)
	prep_start_minutes = current_time_minutes
	update_score_display()
	# Remove prato anterior, se existir
	if drop_plate_area and drop_plate_area.is_inside_tree():
		drop_plate_area.queue_free()

	# Cria um novo prato
	drop_plate_area = drop_plate_scene.instantiate()
	drop_plate_parent.add_child(drop_plate_area)

	# Posiciona corretamente (opcional, se precisar)
	drop_plate_area.position = Vector2(408, 192)  # ajuste conforme o layout da PrepArea

	# Configura a nova receita
	drop_plate_area.set_current_recipe(current_recipe)

	show_random_client()


func show_random_client() -> void:
	if ClientManager.client_sprites.is_empty():
		push_warning("Nenhum sprite de cliente carregado!")
		return

	var client_sprite: Sprite2D = $Mode_Attendance/ClientSprite
	client_sprite.texture = ClientManager.client_sprites.pick_random()
	client_sprite.visible = true
	client_sprite.modulate = Color(1, 1, 1, 0)
	client_sprite.position = Vector2(165, 334)

	$Mode_Attendance/AnimationPlayer.play("client_entrance")

func _spawn_delivered_plate(delivered_plate: Node) -> void:
	var attendance = $Mode_Attendance
	attendance.add_child(delivered_plate)
	delivered_plate.global_position = Vector2(285,231)


func finalize_attendance(final_score: int, final_payment: int, comment: String) -> void:
	# Mostra fala
	mode_attendance.show_feedback(comment)
	add_money(final_payment)
	show_money_gain(final_payment)
	update_score_display(final_score)

	await get_tree().create_timer(0.5).timeout
	await mode_attendance.hide_client()

	if day_should_end:
		_end_day()
	else:
		switch_mode(GameMode.ATTENDANCE)
		load_new_recipe()
	
	daily_report.append({
	"recipe_name": current_recipe.recipe_name,
	"score": final_score,
	"payment": final_payment
})
	print("Pedido registrado:", daily_report[-1])
	
	var prep_area := $Mode_Preparation/ScrollContainer/PrepArea
	if prep_area.has_method("clear_day_leftovers"):
		prep_area.clear_day_leftovers()
	
	
func show_money_gain(amount: int) -> void:
	var gain_label := $HUD/MoneyLabel/MoneyGainLabel
	gain_label.text = "+%d" % amount
	gain_label.visible = true
	gain_label.modulate.a = 1.0
	gain_label.position = Vector2(25, -20)

	var tween := create_tween()
	tween.tween_property(gain_label, "position:y", -30, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(gain_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_delay(0.3)

	await tween.finished
	gain_label.visible = false
	


func populate_end_of_day_report():
	var income := 0
	var orders_vbox := $Mode_EndOfDay/Panel/OrdersScroll/OrdersVBox
	var expenses := total_ingredient_expense  # <- você já deve estar registrando isso
	print("Pedidos registrados hoje: ", daily_report.size())
	
	# Limpa relatórios anteriores (por segurança)
	for child in orders_vbox.get_children():
		child.queue_free()

	# Preenche a lista de pedidos
	for entry in daily_report:
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size.y = 20
		
		# Estilize como quiser abaixo
		label.bbcode_text = "[font_size=14][color=fef3c0]%s[/color]  [color=white]%d%%[/color]  [color=62ab48]M$%d[/color][/font_size]" % [
			entry["recipe_name"],
			entry["score"],
			entry["payment"]
	]
		orders_vbox.add_child(label)
		income += entry["payment"]

	# Atualiza os resumos
	$Mode_EndOfDay/Panel/SummaryBox/IncomeLabel.text = "Ganhos: M$%d" % income
	$Mode_EndOfDay/Panel/SummaryBox/ExpenseLabel.text = "Gastos: M$%d" % expenses
	$Mode_EndOfDay/Panel/SummaryBox2/ProfitLabel.text = "Lucro: M$%d" % (income - expenses)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		var options_panel = $InGameOptions
		if options_panel.visible:
			options_panel.hide()
			get_tree().paused = false
		else:
			options_panel.show()
			get_tree().paused = true
