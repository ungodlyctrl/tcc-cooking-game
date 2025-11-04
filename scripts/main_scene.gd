extends Node2D
class_name MainScene

## Gerencia modos do jogo e ciclo de dias / receitas.
enum GameMode { ATTENDANCE, PREPARATION, END_OF_DAY }

# ---------------- Variáveis principais ----------------
var current_mode: GameMode = GameMode.ATTENDANCE
var current_time_minutes: int = 8 * 60
var absolute_minutes: int = 8 * 60
var day: int = 5
var money: int = 100

const END_OF_DAY_MINUTES: int = 19 * 60
const HARD_LIMIT_MINUTES: int = 20 * 60
var last_time_of_day: String = ""

var region: String = "sudeste"
var current_recipe: RecipeResource = null
var current_client_lines: Array[String] = []
var current_recipe_variants: Array = []
var prep_start_minutes: int = -1
var pending_delivery: Array[Dictionary] = []
var daily_report: Array = []
var total_ingredient_expense: int = 0
var current_client: ClientData = null

var clock_timer: Timer = Timer.new()
var day_should_end: bool = false

# AUTO-NOTE: abrir só na primeira receita do day inicial
var initial_day_at_start: int = 1
var has_shown_note_first_day: bool = false

# ---------------- Onready ----------------
@onready var mode_attendance: ModeAttendance = $Mode_Attendance
@onready var mode_preparation: ModePreparation = $Mode_Preparation
@onready var mode_end_of_day: ModeEndOfDay = $ModeEndOfDay
@onready var scroll_container: ScrollContainer = $Mode_Preparation/ScrollContainer
@onready var prep_area: PrepArea = $Mode_Preparation/ScrollContainer/PrepArea

# HUD
@onready var clock_label: Label = $HUD/ClockLabel
@onready var money_label: Label = $HUD/MoneyLabel
@onready var day_label: Label = $HUD/DayLabel

# ---------------- Ready ----------------
func _ready() -> void:
	print("Managers:", Managers)
	print("RecipeManager:", Managers.recipe_manager)

	clock_timer.wait_time = 2.7
	clock_timer.timeout.connect(_on_time_tick)
	add_child(clock_timer)
	clock_timer.start()

	switch_mode(GameMode.ATTENDANCE)
	_update_ui()

	# Espera managers carregarem
	await get_tree().process_frame
	load_new_recipe()

	last_time_of_day = get_visual_time_of_day()
	mode_attendance.update_city_background(last_time_of_day)

	# Garante bancada inicial
	prep_area.update_ingredients_for_day(day)


# ---------------- Mode Switch ----------------
func switch_mode(new_mode: GameMode) -> void:
	current_mode = new_mode

	mode_attendance.visible = (new_mode == GameMode.ATTENDANCE)
	mode_preparation.visible = (new_mode == GameMode.PREPARATION)
	mode_end_of_day.visible = (new_mode == GameMode.END_OF_DAY)
	$HUD.visible = (new_mode != GameMode.END_OF_DAY)

	# ⚠️ NÃO esconder nota aqui (o painel é responsável pelo seu estado),
	# apenas escondemos no END_OF_DAY
	if new_mode == GameMode.END_OF_DAY:
		$Mode_Preparation/HUDPrep/RecipeNotePanel.hide()
	else:
		$Mode_Preparation/HUDPrep/RecipeNotePanel.show()

	if new_mode == GameMode.PREPARATION:
		scroll_container.scroll_horizontal = 0
		prep_area.ensure_plate_for_day(day)


# ---------------- Tick / Time ----------------
func _on_time_tick() -> void:
	absolute_minutes += 15

	if current_time_minutes < HARD_LIMIT_MINUTES:
		current_time_minutes += 15
	current_time_minutes = min(current_time_minutes, HARD_LIMIT_MINUTES)

	if absolute_minutes >= END_OF_DAY_MINUTES:
		day_should_end = true

	_update_ui()

	if current_mode == GameMode.PREPARATION:
		update_score_display()

	var visual_time: String = get_visual_time_of_day()
	if visual_time != last_time_of_day:
		last_time_of_day = visual_time
		mode_attendance.update_city_background(visual_time)


func _update_ui() -> void:
	var hours: int = current_time_minutes / 60
	var minutes: int = current_time_minutes % 60

	clock_label.text = "%02d:%02d" % [hours, minutes]
	money_label.text = "M$: " + str(money)
	day_label.text = "Dia " + str(day)

	if absolute_minutes >= END_OF_DAY_MINUTES and not (current_mode == GameMode.END_OF_DAY):
		clock_label.add_theme_color_override("font_color", Color.RED)
	else:
		clock_label.remove_theme_color_override("font_color")


# ---------------- Day Cycle ----------------
func _end_day() -> void:
	clock_timer.stop()
	print("🔹 Fim do dia — Gerando relatório…")

	if mode_end_of_day and mode_end_of_day.has_method("populate"):
		mode_end_of_day.populate(daily_report, total_ingredient_expense, day)
	else:
		push_warning("⚠️ mode_end_of_day.populate() não encontrado!")

	switch_mode(GameMode.END_OF_DAY)


func start_new_day() -> void:
	print("🔹 Iniciando novo dia…")
	day += 1
	current_time_minutes = 8 * 60
	absolute_minutes = 8 * 60
	day_should_end = false
	prep_start_minutes = -1
	daily_report.clear()
	total_ingredient_expense = 0
	pending_delivery.clear()

	last_time_of_day = get_visual_time_of_day()
	mode_attendance.update_city_background(last_time_of_day)
	prep_area.clear_day_leftovers()

	clock_timer.start()
	switch_mode(GameMode.ATTENDANCE)

	await get_tree().process_frame
	load_new_recipe()
	_update_ui()

	var score_label: Label = $HUD/HBoxContainer/ScoreLabel
	score_label.text = "100%"

	prep_area.update_ingredients_for_day(day)
	prep_area.ensure_plate_for_day(day)


# ---------------- Gameplay ----------------
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

	var elapsed_minutes: int = absolute_minutes - prep_start_minutes
	var time_penalty: int = int(elapsed_minutes / 15)
	var score: int = clamp(100 - time_penalty, 0, 100)
	score_label.text = "%d%%" % score


# ---------------- Recipe Loading ----------------
func load_new_recipe() -> void:
	if Managers.recipe_manager == null:
		push_warning("⚠️ RecipeManager ainda não carregado, aguardando...")
		await get_tree().process_frame
		if Managers.recipe_manager == null:
			push_error("❌ RecipeManager não inicializado!")
			return

	var time_of_day := get_time_of_day()
	var result : Dictionary = Managers.recipe_manager.get_random_recipe(day, region, time_of_day)
	if result.is_empty():
		push_warning("⚠️ Nenhuma receita encontrada para %s (%s, Dia %d)" % [region, time_of_day, day])
		return

	current_recipe = result.get("recipe", null)
	current_recipe_variants = result.get("variants", [])
	current_client_lines = result.get("client_lines", [])
	prep_start_minutes = absolute_minutes

	mode_attendance.set_recipe(current_recipe, current_client_lines)

	var score_label: Label = $HUD/HBoxContainer/ScoreLabel
	score_label.text = "100%"

	print("🧾 Enviando receita para RecipeNotePanel:", current_recipe.recipe_name)
	mode_preparation.set_recipe(current_recipe, current_recipe_variants)

	# ⚙️ Aguardar DropPlateArea pronto antes de setar receita
	await get_tree().process_frame
	if prep_area:
		var dpa: DropPlateArea = prep_area.get_node_or_null("UtensilsParent/DropPlateArea")
		if dpa:
			await get_tree().process_frame
			print("✅ DropPlateArea encontrado e configurado")
			dpa.set_current_recipe(current_recipe)
		else:
			print("❌ DropPlateArea não encontrado em PrepArea!")

	update_score_display()
	prep_area.update_ingredients_for_day(day)
	prep_area.ensure_plate_for_day(day)

	if not has_shown_note_first_day and day == initial_day_at_start:
		await get_tree().process_frame
		if mode_preparation and mode_preparation.recipe_note_panel:
			mode_preparation.recipe_note_panel._animate_open()
			has_shown_note_first_day = true

	show_random_client()



# ---------------- Attendance ----------------
func show_random_client() -> void:
	current_client = Managers.client_manager.pick_random_client()
	if current_client == null:
		push_warning("Nenhum cliente disponível!")
		return
	mode_attendance.show_client(current_client)


func _spawn_delivered_plate(delivered_plate: Node) -> void:
	var attendance: Node = $Mode_Attendance
	attendance.add_child(delivered_plate)
	delivered_plate.global_position = Vector2(285, 231)


func finalize_attendance(final_score: int, final_payment: int, comment: String, grade: String = "") -> void:
	# 🔹 salva imediatamente os dados atuais da receita
	var recipe_snapshot := current_recipe if current_recipe else null
	var recipe_name := recipe_snapshot.recipe_name if recipe_snapshot else "—"

	daily_report.append({
		"recipe_name": str(recipe_name),
		"score": int(final_score),
		"payment": int(final_payment),
		"grade": str(grade)
	}.duplicate(true))

	print("Pedido registrado:", daily_report[-1])

	# Agora mostra feedback e faz o resto normalmente
	mode_attendance.show_feedback(comment, grade, current_client)
	add_money(final_payment)
	show_money_gain(final_payment)
	update_score_display(final_score)

	var score_label: Label = $HUD/HBoxContainer/ScoreLabel
	score_label.text = "%d%%" % final_score

	# Tempo de exibição da fala
	var base_time := 0.8
	var extra_time := float(comment.length()) / 40.0
	var wait_time : float = clamp(base_time + extra_time, 0.8, 4.0)

	await get_tree().create_timer(wait_time).timeout
	await mode_attendance.hide_client()

	# 🔹 Limpeza e preparação para o próximo pedido
	prep_area.clear_day_leftovers()
	prep_area.update_ingredients_for_day(day)
	prep_area.ensure_plate_for_day(day)

	if day_should_end:
		_end_day()
	else:
		switch_mode(GameMode.ATTENDANCE)
		await get_tree().process_frame
		load_new_recipe()


# ---------------- UI ----------------
func show_money_gain(amount: int) -> void:
	var gain_label: Label = $HUD/MoneyLabel/MoneyGainLabel
	gain_label.text = "+%d" % amount
	gain_label.visible = true
	gain_label.modulate.a = 1.0
	gain_label.position = Vector2(25, -20)

	var tween := create_tween()
	tween.tween_property(gain_label, "position:y", -30, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(gain_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_delay(0.3)
	await tween.finished
	gain_label.visible = false


# ---------------- Input ----------------
func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		var options_panel: Control = $InGameOptions
		options_panel.visible = not options_panel.visible
		get_tree().paused = options_panel.visible
