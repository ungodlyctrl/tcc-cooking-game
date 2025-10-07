extends Control
class_name RecipeNotePanel

@onready var note_bg: NinePatchRect = $NoteBackground
@onready var margin: MarginContainer = $NoteBackground/MarginContainer
@onready var scroll: ScrollContainer = $NoteBackground/MarginContainer/ScrollContainer
@onready var content_box: VBoxContainer = $NoteBackground/MarginContainer/ScrollContainer/ContentBox
@onready var title_label: RichTextLabel = $NoteBackground/MarginContainer/ScrollContainer/ContentBox/RecipeTitle
@onready var ingredient_label: RichTextLabel = $NoteBackground/MarginContainer/ScrollContainer/ContentBox/IngredientList
@onready var steps_label: RichTextLabel = $NoteBackground/MarginContainer/ScrollContainer/ContentBox/PreparationSteps

var current_recipe: RecipeResource = null
var current_variants: Array = []

const CLOSED_SIZE: Vector2 = Vector2(180, 10)
const OPEN_WIDTH: int = 180
const MIN_HEIGHT: int = 120
const MAX_HEIGHT: int = 240

# --- cores / formato ---
# Cores ajustadas para maior contraste e leitura confortável
const TITLE_BBCODE := "[font_size=16][color=#1a0d00]%s[/color][/font_size]\n"
const SECTION_COLOR := "#1a0d00"      # cor das seções ("Ingredientes", "Modo de preparo")
const TEXT_COLOR := "#2b1a10"         # cor do texto principal (itens e instruções)
const LIGHT_TEXT_COLOR := "#3b2415"   # cor das linhas finais (mais escura que antes)

var is_open: bool = false

const INNER_HORIZONTAL_PADDING: int = 12
const HEADER_EXTRA: int = 20

func _ready() -> void:
	await get_tree().process_frame

	# Corrige comportamento dos labels e scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	for lbl in [title_label, ingredient_label, steps_label]:
		if lbl and lbl is RichTextLabel:
			lbl.bbcode_enabled = true
			lbl.scroll_active = false
			lbl.visible_characters = -1
			lbl.fit_content = true
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			lbl.clear()
		else:
			push_warning("⚠️ RecipeNotePanel: um label não foi inicializado corretamente.")

	# Margens internas
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)

	# Começa fechado
	note_bg.custom_minimum_size = CLOSED_SIZE
	scroll.custom_minimum_size = Vector2(OPEN_WIDTH - INNER_HORIZONTAL_PADDING, max(1, int(CLOSED_SIZE.y)))
	note_bg.modulate.a = 1.0
	is_open = false
	content_box.visible = false

	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	position = Vector2(450, 0)

	note_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	note_bg.gui_input.connect(_on_note_gui_input)

	print("🟢 RecipeNotePanel pronto — posição:", position)


func set_recipe(recipe: RecipeResource, variants: Array = []) -> void:
	current_recipe = recipe
	current_variants = variants.duplicate(true)
	print("🧾 Enviando receita para RecipeNotePanel:", current_recipe.recipe_name if current_recipe else "<null>")
	_update_content()


func _update_content() -> void:
	await get_tree().process_frame

	if current_recipe == null:
		title_label.clear()
		ingredient_label.clear()
		steps_label.clear()
		return

	title_label.bbcode_text = TITLE_BBCODE % current_recipe.recipe_name

	var lines: Array[String] = []
	for req in current_recipe.ingredient_requirements:
		if req == null:
			continue
		var display := _get_display_name(req.ingredient_id)
		var qty := int(req.quantity)
		var qty_text := "" if qty <= 1 else " x%d" % qty
		lines.append("[color=%s]- %s%s[/color]" % [TEXT_COLOR, display, qty_text])

	var ing_block := "[color=%s]Ingredientes:[/color]\n" % SECTION_COLOR
	ing_block += "\n".join(lines)
	ingredient_label.bbcode_text = ing_block

	if "display_steps" in current_recipe and current_recipe.display_steps and current_recipe.display_steps.size() > 0:
		var steps: Array[String] = []
		var excluded_ids := _excluded_ids_from_variants(current_variants)
		for s in current_recipe.display_steps:
			if not _line_mentions_excluded(s, excluded_ids):
				steps.append("[color=%s]- %s[/color]" % [TEXT_COLOR, s])
		var steps_block := "[color=%s]Modo de preparo:[/color]\n" % SECTION_COLOR
		steps_block += "\n".join(steps)
		steps_label.bbcode_text = steps_block
	else:
		steps_label.bbcode_text = _generate_steps_bbcode_filtered(current_recipe, current_variants)

	await get_tree().process_frame
	await get_tree().process_frame


# ---------------------------------------------------------
func _generate_steps_bbcode_filtered(recipe: RecipeResource, variants: Array) -> String:
	var excluded_ids := _excluded_ids_from_variants(variants)
	var step_lines: Array[String] = []

	for req in recipe.ingredient_requirements:
		if req == null:
			continue
		if excluded_ids.has(req.ingredient_id):
			continue

		var ing_data: IngredientData = null
		if Managers and Managers.ingredient_database:
			ing_data = Managers.ingredient_database.get_ingredient(req.ingredient_id)
		var display := _get_display_name(req.ingredient_id)

		if req.stages and req.stages.size() > 0:
			for s in req.stages:
				var verb := _verb_for_stage(s, req, ing_data)
				if verb == "": verb = "Usar"
				step_lines.append("[color=%s]- %s %s[/color]" % [TEXT_COLOR, verb, display])
		else:
			var v := _verb_for_state(req.state, req, ing_data)
			if v == "" or v == null:
				v = "Usar"
			step_lines.append("[color=%s]- %s %s[/color]" % [TEXT_COLOR, v, display])

	if step_lines.is_empty():
		step_lines.append("[color=%s]- Preparar e servir os ingredientes.[/color]" % TEXT_COLOR)

	step_lines.append("")
	step_lines.append("[color=%s][i]Montar no prato e servir ao cliente.[/i][/color]" % LIGHT_TEXT_COLOR)

	var block := "[color=%s]Modo de preparo:[/color]\n" % SECTION_COLOR
	block += "\n".join(step_lines)
	return block


# ---------------------------------------------------------
func _excluded_ids_from_variants(variants: Array) -> Array:
	var excluded: Array[String] = []
	for v in variants:
		if typeof(v) == TYPE_DICTIONARY and not v.get("included", true):
			excluded.append(str(v.get("id", "")))
	return excluded


func _line_mentions_excluded(line: String, excluded_ids: Array) -> bool:
	if excluded_ids.is_empty():
		return false
	for eid in excluded_ids:
		if eid == "": continue
		var dname := _get_display_name(eid).to_lower()
		if eid.to_lower() in line.to_lower() or dname in line.to_lower():
			return true
	return false


# ---------------------------------------------------------
func _verb_for_stage(stage_value: int, req: IngredientRequirement, ing_data: IngredientData) -> String:
	match stage_value:
		IngredientRequirement.Stage.COOKING:
			# checa se já vem cozido
			var idlow := req.ingredient_id.to_lower()
			if _ingredient_is_in_state(ing_data, "cooked", req):
				return "Adicionar"
			if "arroz" in idlow: return "Adicionar"
			if "feijao" in idlow or "feijão" in idlow: return "Adicionar"
			return "Cozinhar"
		IngredientRequirement.Stage.FRYING:
			var idlow := req.ingredient_id.to_lower()
			if "pao" in idlow or "pão" in idlow or "bread" in idlow: return "Tostar"
			if "queijo" in idlow or "cheese" in idlow: return "Dourar / Derreter"
			if "mortadela" in idlow: return "Tostar"
			return "Fritar"
		IngredientRequirement.Stage.CUTTING:
			if _ingredient_is_in_state(ing_data, "cut", req):
				return "Adicionar"
			return "Cortar"
		IngredientRequirement.Stage.MIXING:
			return "Misturar"
		_:
			return ""


func _verb_for_state(state: String, req: IngredientRequirement, ing_data: IngredientData) -> String:
	match state:
		"cooked": return "Cozinhar"
		"fried": return "Fritar"
		"cut": return "Cortar"
		"raw": return "Adicionar"
		_: return "Usar"


# ---------------------------------------------------------
func _ingredient_is_in_state(ing_data: IngredientData, needed_state: String, req: IngredientRequirement = null) -> bool:
	if ing_data and str(ing_data.initial_state) == needed_state:
		return true

	# fallback — tenta recuperar do banco de dados caso ing_data tenha vindo null
	if (ing_data == null or ing_data.initial_state == "") and Managers and Managers.ingredient_database:
		var check_data: IngredientData = Managers.ingredient_database.get_ingredient(req.ingredient_id) if req else null
		if check_data and str(check_data.initial_state) == needed_state:
			return true

	# fallback extra — se o próprio req guarda algo como "initial_state" em metadata (às vezes acontece)
	if req and req.has_meta("initial_state") and str(req.get_meta("initial_state")) == needed_state:
		return true

	return false



func _get_display_name(id: String) -> String:
	if Managers and Managers.ingredient_database:
		var d: IngredientData = Managers.ingredient_database.get_ingredient(id)
		if d and d.display_name != "":
			return d.display_name
	return id.capitalize()


# ---------------------------------------------------------
# Interação / animações
# ---------------------------------------------------------
func _on_note_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_open()


func _toggle_open() -> void:
	if is_open:
		_animate_close()
	else:
		_animate_open()


func _animate_open() -> void:
	if is_open:
		return
	is_open = true

	content_box.visible = true
	scroll.modulate.a = 1.0  # aparece junto da nota

	_update_content()
	await get_tree().process_frame

	var content_h := content_box.get_combined_minimum_size().y + HEADER_EXTRA
	var target_h := int(clamp(content_h, MIN_HEIGHT, MAX_HEIGHT))
	var target_vec := Vector2(OPEN_WIDTH, target_h)

	var tw := create_tween()
	tw.parallel().tween_property(note_bg, "custom_minimum_size", target_vec, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(scroll, "custom_minimum_size", Vector2(OPEN_WIDTH - INNER_HORIZONTAL_PADDING, target_h - HEADER_EXTRA), 0.35)
	await tw.finished

	scroll.scroll_vertical = 0


func _animate_close() -> void:
	if not is_open:
		return
	is_open = false

	var tw := create_tween()
	tw.parallel().tween_property(note_bg, "custom_minimum_size", CLOSED_SIZE, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(scroll, "custom_minimum_size", Vector2(OPEN_WIDTH - INNER_HORIZONTAL_PADDING, CLOSED_SIZE.y), 0.3)
	await tw.finished

	content_box.visible = false
