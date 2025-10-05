extends Control
class_name ModeEndOfDay

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var income_label: Label = $VBoxContainer/PanelContainer/MarginContainer/MainVBox/SummaryBox/IncomeHBox/IncomeLabel
@onready var income_value: Label = $VBoxContainer/PanelContainer/MarginContainer/MainVBox/SummaryBox/IncomeHBox/IncomeValue
@onready var expense_label: Label = $VBoxContainer/PanelContainer/MarginContainer/MainVBox/SummaryBox/ExpenseHBox/ExpenseLabel
@onready var expense_value: Label = $VBoxContainer/PanelContainer/MarginContainer/MainVBox/SummaryBox/ExpenseHBox/ExpenseValue
@onready var orders_vbox: VBoxContainer = $VBoxContainer/PanelContainer/MarginContainer/MainVBox/OrdersScroll/OrdersVBox
@onready var profit_label: Label = $VBoxContainer/PanelContainer/MarginContainer/MainVBox/ProfitHBox/ProfitLabel
@onready var profit_value: Label = $VBoxContainer/PanelContainer/MarginContainer/MainVBox/ProfitHBox/ProfitValue
@onready var next_day_button: Button = $VBoxContainer/NextDayButton
@onready var panel_container: PanelContainer = $VBoxContainer/PanelContainer

var tween: Tween

# 🎨 Cores
const MONEY_POSITIVE: Color = Color(0.43, 0.78, 0.36)
const MONEY_NEGATIVE: Color = Color(0.84, 0.33, 0.33)
const MONEY_NEUTRAL: Color = Color(0.8, 0.8, 0.8)
const MONEY_LABEL_GREEN: Color = Color(0.7, 1.0, 0.7)
const MONEY_LABEL_RED: Color = Color(1.0, 0.6, 0.6)
const ROW_TEXT_COLOR: Color = Color(0.95, 0.94, 0.88)

func _ready() -> void:
	if next_day_button:
		next_day_button.pressed.connect(_on_next_day_pressed)

	visible = false
	panel_container.modulate.a = 0.0
	panel_container.scale = Vector2(0.95, 0.95)
	title_label.modulate.a = 0.0
	next_day_button.visible = false

func _clear_orders() -> void:
	for child in orders_vbox.get_children():
		child.queue_free()

func _create_order_row(entry: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = 20  # 🔹 mais compacto
	row.add_theme_constant_override("separation", 8)  # 🔹 menos espaço entre colunas

	# Nome
	var name_label := Label.new()
	name_label.text = str(entry.get("recipe_name", "—"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", ROW_TEXT_COLOR)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Pontuação (%)
	var score_label := Label.new()
	score_label.text = "%3d%%" % int(entry.get("score", 0))
	score_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	score_label.custom_minimum_size.x = 58  # 🔹 mais perto do dinheiro
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

	# Dinheiro
	var payment := int(entry.get("payment", 0))
	var money_label := Label.new()
	money_label.text = "M$%d" % payment
	money_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	money_label.custom_minimum_size.x = 40  # 🔹 ligeiramente afastado do scroll
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money_label.add_theme_color_override("font_color", MONEY_POSITIVE)

	row.add_child(name_label)
	row.add_child(score_label)
	row.add_child(money_label)
	return row

func populate(daily_report: Array, expenses: int, day_index: int) -> void:
	_clear_orders()

	var income: int = 0
	for entry in daily_report:
		if typeof(entry) == TYPE_DICTIONARY:
			income += int(entry.get("payment", 0))

	title_label.text = "Fim do dia — Dia %d" % int(day_index)
	income_value.text = "M$%d" % income
	expense_value.text = "M$%d" % int(expenses)

	# 🔹 Cores de ganhos e gastos
	income_value.add_theme_color_override("font_color", MONEY_LABEL_GREEN)
	expense_value.add_theme_color_override("font_color", MONEY_LABEL_RED)

	var balance := income - int(expenses)
	profit_label.text = "Balanço:"
	profit_value.text = "M$%d" % balance

	# 🔹 Cor do balanço dinâmica
	if balance > 0:
		profit_value.add_theme_color_override("font_color", MONEY_POSITIVE)
	elif balance < 0:
		profit_value.add_theme_color_override("font_color", MONEY_NEGATIVE)
	else:
		profit_value.add_theme_color_override("font_color", MONEY_NEUTRAL)

	for entry in daily_report:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		orders_vbox.add_child(_create_order_row(entry))

	visible = true
	_animate_appearance()

func _animate_appearance() -> void:
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.tween_property(panel_container, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel_container, "scale", Vector2(1, 1), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(title_label, "modulate:a", 1.0, 0.4).set_delay(0.1)

	await get_tree().create_timer(0.8).timeout
	next_day_button.visible = true
	next_day_button.modulate.a = 0.0
	var btn_tween := create_tween()
	btn_tween.tween_property(next_day_button, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_next_day_pressed() -> void:
	if get_tree().current_scene and get_tree().current_scene.has_method("start_new_day"):
		get_tree().current_scene.start_new_day()
	else:
		push_warning("MainScene não tem start_new_day() ou current_scene não definido.")
