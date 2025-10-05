extends Control
class_name RecipeNotePanel

@onready var note_bg: NinePatchRect = $NoteBackground
@onready var scroll: ScrollContainer = $NoteBackground/ScrollContainer
@onready var content_box: VBoxContainer = $NoteBackground/ScrollContainer/ContentBox
@onready var title_label: RichTextLabel = $NoteBackground/ScrollContainer/ContentBox/RecipeTitle
@onready var ingredient_label: RichTextLabel = $NoteBackground/ScrollContainer/ContentBox/IngredientList
@onready var steps_label: RichTextLabel = $NoteBackground/ScrollContainer/ContentBox/PreparationSteps

var current_recipe: RecipeResource = null
var current_variants: Array = []

# tamanhos e limites
const CLOSED_SIZE: Vector2 = Vector2(180, 40)   # rebarba visível quando fechado
const OPEN_WIDTH: int = 180
const MIN_HEIGHT: int = 120
const MAX_HEIGHT: int = 360

const TITLE_BBCODE := "[font_size=16][color=F5F3E0][b]%s[/b][/color][/font_size]\n"

var is_open: bool = false

func _ready() -> void:
	# configura richtext
	for lbl in [title_label, ingredient_label, steps_label]:
		if lbl and lbl is RichTextLabel:
			lbl.bbcode_enabled = true
			lbl.scroll_active = false
	# estado fechado inicial
	note_bg.custom_minimum_size = CLOSED_SIZE
	note_bg.modulate.a = 1.0  # rebarba visível
	# clique abre/fecha
	note_bg.gui_input.connect(_on_note_gui_input)

# API: aceita optional variants (saída do RecipeManager.apply_variations)
func set_recipe(recipe: RecipeResource, variants: Array = []) -> void:
	current_recipe = recipe
	current_variants = variants.duplicate(true)
	_update_content()

func open() -> void:
	if not is_open:
		_animate_open()

func close() -> void:
	if is_open:
		_animate_close()

# Atualiza textos (ingredientes + passos)
func _update_content() -> void:
	if current_recipe == null:
		title_label.bbcode_text = ""
		ingredient_label.bbcode_text = ""
		steps_label.bbcode_text = ""
		return

	# Título
	title_label.bbcode_text = TITLE_BBCODE % current_recipe.recipe_name

	# Ingredientes
	var lines: Array[String] = []
	for req in current_recipe.ingredient_requirements:
		if req == null: continue
		var display := _get_display_name(req.ingredient_id)
		var qty := int(req.quantity)
		var qty_text := "" if qty <= 1 else " x%d" % qty
		lines.append("- %s%s" % [display, qty_text])
	ingredient_label.bbcode_text = "[b]Ingredientes:[/b]\n" + "\n".join(lines)

	# Passos: usa display_steps se presente, senão gera automaticamente.
	if "display_steps" in current_recipe and current_recipe.display_steps and current_recipe.display_steps.size() > 0:
		# filtra linhas que mencionem ingredientes excluídos (se variants fornecido)
		var steps := []
		var excluded_ids := _excluded_ids_from_variants(current_variants)
		for s in current_recipe.display_steps:
			if not _line_mentions_excluded(s, excluded_ids):
				steps.append("- %s" % s)
		steps_label.bbcode_text = "[b]Modo de preparo:[/b]\n" + "\n".join(steps)
	else:
		steps_label.bbcode_text = _generate_steps_bbcode_filtered(current_recipe, current_variants)

	# força recalculo de tamanho no próximo frame
	await get_tree().process_frame

# Gera passos automaticamente e respeita variants (pula ingredientes omitidos)
func _generate_steps_bbcode_filtered(recipe: RecipeResource, variants: Array) -> String:
	var excluded_ids := _excluded_ids_from_variants(variants)
	var step_lines: Array[String] = []

	for req in recipe.ingredient_requirements:
		if req == null: continue
		if excluded_ids.has(req.ingredient_id):
			continue  # pular ingrediente omitido

		var ing_data := null
		if Managers and Managers.ingredient_database:
			ing_data = Managers.ingredient_database.get_ingredient(req.ingredient_id)
		var display := _get_display_name(req.ingredient_id)

		# se stages definidos, gera por stage
		if req.stages and req.stages.size() > 0:
			for s in req.stages:
				var verb := _verb_for_stage(s, req, ing_data)
				if verb == "":
					verb = "Usar"
				step_lines.append("- %s %s" % [verb, display])
		else:
			var v := _verb_for_state(req.state, req, ing_data)
			step_lines.append("- %s %s" % [v, display])

	step_lines.append("")
	step_lines.append("[i]Montar no prato e servir ao cliente.[/i]")
	return "[b]Modo de preparo:[/b]\n" + "\n".join(step_lines)

# Extrai excluded ids das variants [{id,included,quantity}, ...]
func _excluded_ids_from_variants(variants: Array) -> Array:
	var excluded := []
	for v in variants:
		if typeof(v) == TYPE_DICTIONARY:
			if not v.get("included", true):
				excluded.append(str(v.get("id", "")))
	return excluded

# verifica se a linha menciona algum id ou display_name da lista de excluded
func _line_mentions_excluded(line: String, excluded_ids: Array) -> bool:
	if excluded_ids.empty():
		return false
	for eid in excluded_ids:
		if eid == "": continue
		# tenta display_name também
		var dname := _get_display_name(eid).to_lower()
		if eid.to_lower() in line.to_lower() or dname in line.to_lower():
			return true
	return false

# heurísticas de verbo por stage / state
func _verb_for_stage(stage_value: int, req: IngredientRequirement, ing_data) -> String:
	match stage_value:
		IngredientRequirement.Stage.COOKING:
			if _ingredient_is_in_state(ing_data, "cooked"): return "Adicionar"
			return "Cozinhar"
		IngredientRequirement.Stage.FRYING:
			var idlow := req.ingredient_id.to_lower()
			if "pao" in idlow or "pão" in idlow or "bread" in idlow:
				return "Tostar"
			if "queijo" in idlow or "cheese" in idlow:
				return "Dourar / Derreter"
			return "Fritar"
		IngredientRequirement.Stage.CUTTING:
			if _ingredient_is_in_state(ing_data, "cut"): return "Adicionar"
			return "Cortar"
		IngredientRequirement.Stage.MIXING:
			return "Misturar"
		_:
			return ""

func _verb_for_state(state: String, req: IngredientRequirement, ing_data) -> String:
	match state:
		"cooked":
			if _ingredient_is_in_state(ing_data, "cooked"): return "Adicionar"
			return "Cozinhar"
		"fried":
			var idlow := req.ingredient_id.to_lower()
			if "pao" in idlow or "pão" in idlow: return "Tostar"
			return "Fritar"
		"cut":
			if _ingredient_is_in_state(ing_data, "cut"): return "Adicionar"
			return "Cortar"
		"raw":
			if _ingredient_is_in_state(ing_data, "raw"): return "Adicionar cru"
			return "Preparar cru"
		_:
			return "Usar"

# verifica ingrediente inicial (usa `initial_state` do IngredientData se disponível)
func _ingredient_is_in_state(ing_data, needed_state: String) -> bool:
	if ing_data == null:
		return false
	# garante string
	var s: String = str(ing_data.get("initial_state", ""))
	if s == "": return false
	return s == needed_state

func _get_display_name(id: String) -> String:
	if Managers and Managers.ingredient_database:
		var d := Managers.ingredient_database.get_ingredient(id)
		if d and d.display_name != "":
			return d.display_name
	return id.capitalize()

# UI: clique na rebarba abre/fecha
func _on_note_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_open()

func _toggle_open() -> void:
	if is_open:
		_animate_close()
	else:
		_animate_open()

# Animações: animamos custom_minimum_size (x = largura, y = altura)
func _animate_open() -> void:
	if is_open: return
	is_open = true
	# atualiza conteúdo antes de abrir
	_update_content()
	await get_tree().process_frame

	# calcula altura necessária
	var content_h := content_box.get_combined_minimum_size().y + 28
	var target_h := clamp(int(content_h), MIN_HEIGHT, MAX_HEIGHT)
	var target_vec := Vector2(OPEN_WIDTH, target_h)

	var tw := create_tween()
	tw.tween_property(note_bg, "custom_minimum_size", target_vec, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# opcional: ajustar alpha para suavizar
	tw.tween_property(note_bg, "modulate:a", 1.0, 0.25)
	await tw.finished

func _animate_close() -> void:
	if not is_open: return
	is_open = false
	var tw := create_tween()
	tw.tween_property(note_bg, "custom_minimum_size", CLOSED_SIZE, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
