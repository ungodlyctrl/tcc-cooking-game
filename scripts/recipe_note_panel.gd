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

const CLOSED_SIZE := Vector2(180, 10)
const OPEN_WIDTH := 180
const MIN_HEIGHT := 120
const MAX_HEIGHT := 240

const TITLE_BBCODE := "[font_size=18][color=#0f1735]%s[/color][/font_size]\n"
const SECTION_COLOR := "0f1735"
const TEXT_COLOR := "0f1735"
const LIGHT_TEXT_COLOR := "#0f1735"

var is_open := false

const INNER_HORIZONTAL_PADDING := 12
const HEADER_EXTRA := 20


func _ready() -> void:
	scroll.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	scroll.add_theme_stylebox_override("scroll_v", StyleBoxEmpty.new())
	scroll.add_theme_stylebox_override("scroll_h", StyleBoxEmpty.new())

	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	for lbl in [title_label, ingredient_label, steps_label]:
		lbl.bbcode_enabled = true
		lbl.fit_content = true
		lbl.visible_characters = -1
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.clear()

	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)

	note_bg.custom_minimum_size = CLOSED_SIZE
	scroll.custom_minimum_size = Vector2(OPEN_WIDTH - INNER_HORIZONTAL_PADDING, CLOSED_SIZE.y)

	content_box.visible = false

	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	position = Vector2(450, 0)

	note_bg.mouse_filter = MOUSE_FILTER_STOP
	note_bg.gui_input.connect(_on_note_gui_input)



func set_recipe(recipe: RecipeResource, variants: Array = []) -> void:
	current_recipe = recipe
	current_variants = variants.duplicate(true)
	_update_content(false)



func _update_content(premeasure: bool) -> void:
	if current_recipe == null:
		title_label.clear()
		ingredient_label.clear()
		steps_label.clear()
		return

	title_label.bbcode_text = TITLE_BBCODE % current_recipe.recipe_name

	var ing_lines: Array[String] = []

	for req in current_recipe.ingredient_requirements:
		if req == null:
			continue

		var name := _get_display_name(req.ingredient_id)
		var qty := int(req.quantity)
		var icon := _get_ingredient_icon_bbcode(req.ingredient_id, req.state)

		ing_lines.append("[color=%s]- %s x%d %s[/color]" % [TEXT_COLOR, icon, qty, name])

	ingredient_label.bbcode_text = "[color=%s]Ingredientes:[/color]\n%s" % [SECTION_COLOR, "\n".join(ing_lines)]

	var variant_steps := _get_variant_display_steps(current_recipe, current_variants)

	if variant_steps.size() > 0:
		steps_label.bbcode_text = _format_steps_block(variant_steps)
	else:
		if current_recipe.display_steps.size() > 0:
			var excluded := _excluded_ids_from_variants(current_variants)
			var filtered: Array[String] = []

			for s in current_recipe.display_steps:
				if not _line_mentions_excluded(s, excluded):
					filtered.append(s)

			if filtered.size() > 0:
				steps_label.bbcode_text = _format_steps_block(filtered)
			else:
				steps_label.bbcode_text = _generate_steps_bbcode_filtered(current_recipe, current_variants)
		else:
			steps_label.bbcode_text = _generate_steps_bbcode_filtered(current_recipe, current_variants)

	if premeasure:
		content_box.visible = true
		await get_tree().process_frame
		return



func _on_note_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
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

	_update_content(true)
	content_box.visible = true
	_set_content_alpha(0.0)

	await get_tree().process_frame

	var content_h := content_box.get_combined_minimum_size().y + HEADER_EXTRA
	var target_h := int(clamp(content_h, MIN_HEIGHT, MAX_HEIGHT))

	# CORRIGIDO – sem ternário inválido
	if content_h > MAX_HEIGHT:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	else:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	scroll.custom_minimum_size = Vector2(
		OPEN_WIDTH - INNER_HORIZONTAL_PADDING,
		target_h - HEADER_EXTRA
	)

	var tw := create_tween()
	tw.set_parallel(true)

	tw.tween_property(
		note_bg, "custom_minimum_size",
		Vector2(OPEN_WIDTH, target_h), 0.28
	).set_trans(Tween.TRANS_BACK)

	tw.tween_property(
		scroll, "custom_minimum_size",
		Vector2(OPEN_WIDTH - INNER_HORIZONTAL_PADDING, target_h - HEADER_EXTRA),
		0.28
	)

	await tw.finished

	# FADE-IN
	var tw2 := create_tween()
	tw2.tween_property(self, "modulate:a", 1.0, 0.00001)
	await tw2.finished

	_set_content_alpha(1.0)
	scroll.scroll_vertical = 0




func _animate_close() -> void:
	if not is_open:
		return
	is_open = false

	# fade out do texto antes de subir
	_set_content_alpha(0.0)

	var tw := create_tween()
	tw.set_parallel(true)

	tw.tween_property(
		note_bg, "custom_minimum_size",
		CLOSED_SIZE, 0.22
	)

	tw.tween_property(
		scroll, "custom_minimum_size",
		Vector2(OPEN_WIDTH - INNER_HORIZONTAL_PADDING, CLOSED_SIZE.y),
		0.22
	)

	await tw.finished

	content_box.visible = false



func _set_content_alpha(a: float) -> void:
	for lbl in [title_label, ingredient_label, steps_label]:
		lbl.modulate.a = a


# ============= HELPERS =============

func _get_variant_display_steps(recipe: RecipeResource, variants: Array) -> Array[String]:
	if recipe.display_steps_variants.size() == 0:
		return []

	var excluded := _excluded_ids_from_variants(variants)
	excluded.sort()

	for v in recipe.display_steps_variants:
		if not (v is DisplayStepsVariant):
			continue

		var missing := v.missing.duplicate()
		missing.sort()

		if missing == excluded:
			return v.steps.duplicate()

	return []


func _format_steps_block(lines: Array[String]) -> String:
	var out := []

	for s in lines:
		out.append("[color=%s]- %s[/color]" % [TEXT_COLOR, s])

	out.append("")
	out.append("[color=%s][i]Montar no prato e servir ao cliente.[/i][/color]" % LIGHT_TEXT_COLOR)

	return "[color=%s]Modo de preparo:[/color]\n%s" % [SECTION_COLOR, "\n".join(out)]


func _generate_steps_bbcode_filtered(recipe: RecipeResource, variants: Array) -> String:
	var excluded := _excluded_ids_from_variants(variants)
	var lines: Array[String] = []

	for req in recipe.ingredient_requirements:
		if req == null or excluded.has(req.ingredient_id):
			continue

		var data := Managers.ingredient_database.get_ingredient(req.ingredient_id)
		var name := _get_display_name(req.ingredient_id)

		if req.stages.size() > 0:
			for s in req.stages:
				var verb := _verb_for_stage(s, req, data)
				if verb == "":
					verb = "Usar"
				lines.append("[color=%s]- %s %s[/color]" % [TEXT_COLOR, verb, name])
		else:
			var verb2 := _verb_for_state(req.state, req, data)
			if verb2 == "":
				verb2 = "Usar"
			lines.append("[color=%s]- %s %s[/color]" % [TEXT_COLOR, verb2, name])

	if lines.size() == 0:
		lines.append("[color=%s]- Preparar e servir os ingredientes.[/color]" % TEXT_COLOR)

	lines.append("")
	lines.append("[color=%s][i]Montar no prato e servir ao cliente.[/i][/color]" % LIGHT_TEXT_COLOR)

	return "[color=%s]Modo de preparo:[/color]\n%s" % [SECTION_COLOR, "\n".join(lines)]


func _excluded_ids_from_variants(variants: Array) -> Array[String]:
	var out: Array[String] = []
	for v in variants:
		if typeof(v) == TYPE_DICTIONARY and not v.get("included", true):
			out.append(str(v.get("id", "")))
	return out


func _line_mentions_excluded(line: String, excluded: Array) -> bool:
	for id in excluded:
		if id == "":
			continue
		var disp := _get_display_name(id).to_lower()
		if id.to_lower() in line.to_lower() or disp in line.to_lower():
			return true
	return false


func _verb_for_stage(stage_value: int, req: IngredientRequirement, data: IngredientData) -> String:
	match stage_value:
		IngredientRequirement.Stage.COOKING:
			if _ingredient_is_in_state(data, "cooked", req): return "Adicionar"
			return "Cozinhar"

		IngredientRequirement.Stage.FRYING:
			var id := req.ingredient_id.to_lower()
			if "pao" in id or "pão" in id: return "Tostar"
			if "queijo" in id: return "Dourar / Derreter"
			if "mortadela" in id: return "Tostar"
			return "Fritar"

		IngredientRequirement.Stage.CUTTING:
			if _ingredient_is_in_state(data, "cut", req): return "Adicionar"
			return "Cortar"

		IngredientRequirement.Stage.MIXING:
			return "Misturar"

		_:
			return ""


func _verb_for_state(state: String, req: IngredientRequirement, data: IngredientData) -> String:
	match state:
		"cooked": return "Cozinhar"
		"fried": return "Fritar"
		"cut": return "Cortar"
		"raw": return "Adicionar"
		_: return "Usar"


func _ingredient_is_in_state(data: IngredientData, needed: String, req: IngredientRequirement = null) -> bool:
	if data != null and str(data.initial_state) == needed:
		return true
	if req != null and req.has_meta("initial_state") and str(req.get_meta("initial_state")) == needed:
		return true
	return false


func _get_display_name(id: String) -> String:
	var d := Managers.ingredient_database.get_ingredient(id)
	if d != null and d.display_name != "":
		return d.display_name
	return id.capitalize()


func _get_ingredient_icon_bbcode(id: String, state: String) -> String:
	var tex := Managers.ingredient_database.get_mini_icon(id, state)
	if tex == null:
		return ""
	return "[img=14]" + tex.resource_path + "[/img]"
