extends Node2D
class_name MainScene
## Gerencia modos do jogo e ciclo de dias / receitas.

enum GameMode { ATTENDANCE, PREPARATION, END_OF_DAY }

# ---------------- Variáveis principais ----------------
var current_mode: GameMode = GameMode.ATTENDANCE
var current_time_minutes: int = 8 * 60
var absolute_minutes: int = 8 * 60
var day: int = 1
var money: int = 100

const END_OF_DAY_MINUTES: int = 19 * 60
const HARD_LIMIT_MINUTES: int = 20 * 60

var last_time_of_day: String = ""
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

var initial_day_at_start: int = 1
var has_shown_note_first_day: bool = false

var _is_dragging_plate: bool = false



# ---------------- Onready ----------------
@onready var mode_attendance: ModeAttendance = $Mode_Attendance
@onready var mode_preparation: ModePreparation = $Mode_Preparation
@onready var mode_end_of_day: ModeEndOfDay = $ModeEndOfDay
@onready var scroll_container: ScrollContainer = $Mode_Preparation/ScrollContainer
@onready var prep_area: PrepArea = $Mode_Preparation/ScrollContainer/PrepArea
@onready var region_map: RegionMap = $RegionMap


# HUD
@onready var clock_label: Label = $HUD/ClockLabel
@onready var money_label: Label = $HUD/MoneyLabel
@onready var day_label: Label = $HUD/DayLabel


# ---------------- Ready ----------------
func _ready() -> void:
	clock_timer.wait_time = 2.7
	clock_timer.timeout.connect(_on_time_tick)
	add_child(clock_timer)
	clock_timer.start()

	switch_mode(GameMode.ATTENDANCE)
	_update_ui()

	await get_tree().process_frame
	_apply_region_to_preparea()

	load_new_recipe()

	last_time_of_day = get_visual_time_of_day()
	mode_attendance.update_city_background(last_time_of_day)

	# bancada inicial
	prep_area.update_ingredients_for_day(day)
	_connect_plate_drag_signal()
	
	var bowl_node := prep_area.get_node_or_null("UtensilsParent/BowlArea")
	if bowl_node:
		if bowl_node.is_connected("drag_state_changed", Callable(self, "_on_bowl_drag_state_changed")):
			bowl_node.disconnect("drag_state_changed", Callable(self, "_on_bowl_drag_state_changed"))
			bowl_node.connect("drag_state_changed", Callable(self, "_on_bowl_drag_state_changed"))


# ---------------- REGION HOOK ----------------
func _apply_region_to_preparea() -> void:
	var region_resource := Managers.region_manager.get_current_region()
	if region_resource == null:
		push_warning("⚠ Nenhuma região atual encontrada!")
		return

	prep_area.set_region(region_resource)


# ---------------- Drag Signal ----------------
func _connect_plate_drag_signal() -> void:
	if not prep_area:
		return

	var plate_node := prep_area.get_node_or_null("UtensilsParent/DropPlateArea")
	if plate_node and is_instance_valid(plate_node):
		if plate_node.is_connected("drag_state_changed", Callable(self, "_on_plate_drag_state_changed")):
			plate_node.disconnect("drag_state_changed", Callable(self, "_on_plate_drag_state_changed"))

		plate_node.connect("drag_state_changed", Callable(self, "_on_plate_drag_state_changed"))


func _on_plate_drag_state_changed(is_dragging: bool) -> void:
	_is_dragging_plate = is_dragging
	set_process_input(not is_dragging)


# ---------------- Mode Switch ----------------
func switch_mode(new_mode: GameMode) -> void:
	if _is_dragging_plate:
		await get_tree().process_frame
		if _is_dragging_plate:
			return

	current_mode = new_mode

	mode_attendance.visible = (new_mode == GameMode.ATTENDANCE)
	mode_preparation.visible = (new_mode == GameMode.PREPARATION)
	mode_end_of_day.visible = (new_mode == GameMode.END_OF_DAY)

	$HUD.visible = (new_mode != GameMode.END_OF_DAY)

	if new_mode == GameMode.END_OF_DAY:
		$Mode_Preparation/HUDPrep/RecipeNotePanel.hide()
	else:
		$Mode_Preparation/HUDPrep/RecipeNotePanel.show()

	if new_mode == GameMode.PREPARATION:
		scroll_container.scroll_horizontal = 0
		prep_area.ensure_plate_for_day(day)
		_connect_plate_drag_signal()

	if new_mode == GameMode.ATTENDANCE:
		AudioManager.play_ambience_random(AudioManager.library.ambience_street_tracks)
	else:
		AudioManager.stop_ambience_fade(0.7)
# ---------------- Time Tick ----------------
func _on_time_tick() -> void:

	if _is_dragging_plate:
		return

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
	var hours := current_time_minutes / 60
	var minutes := current_time_minutes % 60
	clock_label.text = "%02d:%02d" % [hours, minutes]
	money_label.text = "M$ " + str(money)
	day_label.text = "Dia " + str(day)

	if absolute_minutes >= END_OF_DAY_MINUTES and current_mode != GameMode.END_OF_DAY:
		clock_label.add_theme_color_override("font_color", Color("d9292fff"))


# ---------------- Day Cycle ----------------
func _end_day() -> void:
	if _is_dragging_plate:
		return

	clock_timer.stop()

	if mode_end_of_day and mode_end_of_day.has_method("populate"):
		mode_end_of_day.populate(daily_report, total_ingredient_expense, day)

	switch_mode(GameMode.END_OF_DAY)


func start_new_day() -> void:
	if _is_dragging_plate:
		return

	day += 1
	current_time_minutes = 8 * 60
	absolute_minutes = 8 * 60
	day_should_end = false
	prep_start_minutes = -1

	# 🔥 Reset da cor do relógio ao iniciar um novo dia
	clock_label.remove_theme_color_override("font_color")


	daily_report.clear()
	total_ingredient_expense = 0
	pending_delivery.clear()

	# aplica troca de região
	Managers.region_manager.apply_pending_change()
	_apply_region_to_preparea()

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
	_connect_plate_drag_signal()


# ---------------- Gameplay ----------------
func add_money(amount: int) -> void:
	money += amount
	_update_ui()


func get_time_of_day() -> String:
	if current_time_minutes < 12 * 60:
		return "breakfast"

	if current_time_minutes < 17 * 60:
		return "lunch"

	return "dinner"


func get_visual_time_of_day() -> String:
	if current_time_minutes < 16 * 60:
		return "morning"

	if current_time_minutes < 18 * 60:
		return "afternoon"

	return "night"


func update_score_display(optional_score: int = -1) -> void:
	var score_label: Label = $HUD/HBoxContainer/ScoreLabel

	if optional_score >= 0:
		score_label.text = "%d%%" % optional_score
		return

	if current_recipe == null or prep_start_minutes < 0:
		return

	var elapsed_minutes := absolute_minutes - prep_start_minutes
	var time_penalty := int(elapsed_minutes / 15)
	var score = clamp(100 - time_penalty, 0, 100)

	score_label.text = "%d%%" % score


# ---------------- Load Recipe ----------------
func load_new_recipe() -> void:
	if _is_dragging_plate:
		return

	var region_id := Managers.region_manager.current_region_id
	var time_of_day := get_time_of_day()

	var result := Managers.recipe_manager.get_random_recipe(day, region_id, time_of_day)
	if result.is_empty():
		push_warning("⚠ Nenhuma receita válida encontrada para região '%s'" % region_id)
		return

	current_recipe = result.get("recipe")
	current_recipe_variants = result.get("variants")
	current_client_lines = result.get("client_lines")

	prep_start_minutes = absolute_minutes

	mode_attendance.set_recipe(current_recipe, current_client_lines)

	var score_label: Label = $HUD/HBoxContainer/ScoreLabel
	score_label.text = "100%"

	mode_preparation.set_recipe(current_recipe, current_recipe_variants)

	await get_tree().process_frame

	if prep_area:
		var dpa: DropPlateArea = prep_area.get_node_or_null("UtensilsParent/DropPlateArea")
		if dpa:
			dpa.set_current_recipe(current_recipe)
			_connect_plate_drag_signal()

	update_score_display()
	prep_area.update_ingredients_for_day(day)
	prep_area.ensure_plate_for_day(day)

	if not has_shown_note_first_day and day == initial_day_at_start:
		await get_tree().process_frame
		mode_preparation.recipe_note_panel._animate_open()
		has_shown_note_first_day = true

	show_random_client()


# ---------------- Attendance ----------------
func show_random_client() -> void:
	var region_id := Managers.region_manager.current_region_id
	current_client = Managers.client_manager.pick_random_client(region_id)

	if current_client == null:
		push_warning("Nenhum cliente disponível para região '%s'" % region_id)
		return

	mode_attendance.show_client(current_client)


func _spawn_delivered_plate(delivered_plate: Node) -> void:
	var attendance := $Mode_Attendance
	attendance.add_child(delivered_plate)
	delivered_plate.global_position = Vector2(285, 231)


func finalize_attendance(final_score: int, final_payment: int, comment: String, grade: String = "") -> void:
	if _is_dragging_plate:
		return

	var recipe_name := "—"
	if current_recipe:
		recipe_name = current_recipe.recipe_name

	daily_report.append({
		"recipe_name": recipe_name,
		"score": final_score,
		"payment": final_payment,
		"grade": grade
	}.duplicate(true))

	mode_attendance.show_feedback(comment, grade, current_client)

	add_money(final_payment)
	show_money_gain(final_payment)

	update_score_display(final_score)

	var score_label: Label = $HUD/HBoxContainer/ScoreLabel
	score_label.text = "%d%%" % final_score

	var wait_time = clamp(0.8 + float(comment.length()) / 40.0, 0.8, 4.0)
	await get_tree().create_timer(wait_time).timeout

	await mode_attendance.hide_client()

	prep_area.clear_day_leftovers()
	prep_area.update_ingredients_for_day(day)
	prep_area.ensure_plate_for_day(day)

	if day_should_end:
		_end_day()
	else:
		switch_mode(GameMode.ATTENDANCE)
		await get_tree().process_frame
		load_new_recipe()




# ---------------- Input ----------------
func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		var options_panel: Control = $InGameOptions
		options_panel.visible = not options_panel.visible
		get_tree().paused = options_panel.visible



func open_region_map() -> void:
	if region_map:
		region_map.open()






func _on_bowl_drag_state_changed(is_dragging: bool) -> void:
	if is_dragging:
		set_process_input(false)
	else:
		set_process_input(true)




# ---------------- UI Money Animations ----------------

func _spawn_money_float(text: String, color: Color, direction: int) -> void:
	# direction: 1 = direita, -1 = esquerda

	var label := Label.new()
	label.text = text
	label.modulate = color
	label.modulate.a = 0.0     # começa invisível
	label.add_theme_font_size_override("font_size", 16)

	# adiciona no HUD ao lado do MoneyLabel
	var hud := $HUD/MoneyLabel
	hud.add_child(label)

	label.position = Vector2(hud.size.x, 0)  # posição inicial

	# animações
	var tween := create_tween()
	tween.set_parallel(true)

	# Fade in rápido + pop
	label.scale = Vector2(0.2, 0.2)
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)

	# Slide lateral
	var slide_offset := Vector2(5 * direction, 0)
	tween.tween_property(label, "position", label.position + slide_offset, 0.2).set_delay(0.05)

	# Fade out
	var tween2 := create_tween()
	tween2.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.4)
	await tween2.finished

	label.queue_free()


func show_money_gain(amount: int) -> void:
	_spawn_money_float("+%d" % amount, Color(0.2, 0.9, 0.2), 1)


func show_money_loss(amount: int) -> void:
	_spawn_money_float("-%d" % amount, Color(0.9, 0.2, 0.2), 1)
