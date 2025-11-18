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

# --- cores ---
const TITLE_BBCODE := "[font_size=16][color=#1a0d00]%s[/color][/font_size]\n"
const SECTION_COLOR := "#1a0d00"
const TEXT_COLOR := "#2b1a10"
const LIGHT_TEXT_COLOR := "#3b2415"

var is_open: bool = false

const INNER_HORIZONTAL_PADDING: int = 12
const HEADER_EXTRA: int = 20


# ============================================================
# READY
# ============================================================
func _ready() -> void:
	await get_tree().process_frame

	# por padrão não mostrar barra vertical (vamos só ativar quando necessário)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

	for lbl in [title_label, ingredient_label, steps_label]:
		lbl.bbcode_enabled = true
		lbl.scroll_active = false
		lbl.visible_characters = -1
		lbl.fit_content = true
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.clear()

	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)

	note_bg.custom_minimum_size = CLOSED_SIZE
	# tamanho inicial do scroll (ajustado quando abrir)
	scroll.custom_minimum_size = Vector2(OPEN_WIDTH - INNER_HORIZONTAL_PADDING, CLOSED_SIZE.y)
	content_box.visible = false

	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	position = Vector2(450, 0)

	note_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	note_bg.gui_input.connect(_on_note_gui_input)


# ============================================================
# RECEITA
# ============================================================
func set_recipe(recipe: RecipeResource, variants: Array = []) -> void:
	current_recipe = recipe
	current_variants = variants.duplicate(true)
	_update_content()


func _update_content() -> void:
	# espera frame pra garantir que nodes/labels tenham tamanho correto
	await get_tree().process_frame

	if current_recipe == null:
		title_label.clear()
		ingredient_label.clear()
		steps_label.clear()
		return

	# -------------------- TÍTULO --------------------
	title_label.bbcode_text = TITLE_BBCODE % current_recipe.recipe_name

	# -------------------- INGREDIENTES --------------------
	var ing_lines: Array[String] = []
	for req in current_recipe.ingredient_requirements:
		if req == null:
			continue

		var name := _get_display_name(req.ingredient_id)
		var qty := int(req.quantity)
		# sempre exibir quantidade (x1, x2...)
		var qty_txt := "x%d" % qty

		# ícone (bbcode img) — fica antes da quantidade
		var icon_bb := _get_ingredient_icon_bbcode(req.ingredient_id, req.state)
		var icon_prefix := "" if icon_bb == "" else "%s " % icon_bb

		# novo formato: icone + quantidade + nome  (ex: [img] x2 Presunto)
		ing_lines.append("[color=%s]- %s%s %s[/color]" % [
			TEXT_COLOR,
			icon_prefix,
			qty_txt,
			name
		])

	ingredient_label.bbcode_text = "[color=%s]Ingredientes:[/color]\n%s" % [
		SECTION_COLOR,
		"\n".join(ing_lines)
	]

	# -------------------- MODO DE PREPARO --------------------

	# 1) Tenta variantes específicas
	var variant_steps := _get_variant_display_steps(current_recipe, current_variants)
	if not variant_steps.is_empty():
		steps_label.bbcode_text = _format_steps_block(variant_steps)
		_post_update_layout_and_scroll()
		return

	# 2) Usa display_steps normal (com filtragem)
	if current_recipe.display_steps.size() > 0:
		var excluded := _excluded_ids_from_variants(current_variants)
		var filtered : Array[String] = []

		for s in current_recipe.display_steps:
			if not _line_mentions_excluded(s, excluded):
				filtered.append(s)

		if filtered.is_empty():
			steps_label.bbcode_text = _generate_steps_bbcode_filtered(current_recipe, current_variants)
			_post_update_layout_and_scroll()
			return

		steps_label.bbcode_text = _format_steps_block(filtered)
		_post_update_layout_and_scroll()
		return

	# 3) Fallback automático
	steps_label.bbcode_text = _generate_steps_bbcode_filtered(current_recipe, current_variants)
	_post_update_layout_and_scroll()


# chama após atualizar bbcode para medir e ajustar scroll (reaproveitado)
func _post_update_layout_and_scroll() -> void:
	# espera um frame ou dois para o RichTextLabel recalcular tamanho corretamente
	await get_tree().process_frame
	await get_tree().process_frame

	var content_h := content_box.get_combined_minimum_size().y + HEADER_EXTRA
	# decide se mostra a barra vertical
	if content_h > MAX_HEIGHT:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	else:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

	# ajusta o custom_minimum_size do scroll pra ficar alinhado com a animação
	var target_h := int(clamp(content_h, MIN_HEIGHT, MAX_HEIGHT))
	scroll.custom_minimum_size = Vector2(OPEN_WIDTH - INNER_HORIZONTAL_PADDING, target_h - HEADER_EXTRA)


# ============================================================
# VARIANTES PERSONALIZADAS
# ============================================================
func _get_variant_display_steps(recipe: RecipeResource, variants: Array) -> Array[String]:
	if recipe.display_steps_variants.is_empty():
		return [] as Array[String]

	var excluded := _excluded_ids_from_variants(variants)
	var sorted_missing := excluded.duplicate()
	sorted_missing.sort()

	for var_res in recipe.display_steps_variants:
		if not (var_res is DisplayStepsVariant):
			continue

		var missing := var_res.missing.duplicate()
		missing.sort()

		if missing == sorted_missing:
			print(" ✔ VARIANTE ENCONTRADA!")
			return var_res.steps.duplicate(true) as Array[String]

	return [] as Array[String]


# ============================================================
# FORMATADOR DE BLOCO DE PASSOS
# ============================================================
func _format_steps_block(lines: Array[String]) -> String:
	var out := []

	for s in lines:
		out.append("[color=%s]- %s[/color]" % [TEXT_COLOR, s])

	out.append("")
	out.append("[color=%s][i]Montar no prato e servir ao cliente.[/i][/color]" % LIGHT_TEXT_COLOR)

	return "[color=%s]Modo de preparo:[/color]\n%s" % [SECTION_COLOR, "\n".join(out)]


# ============================================================
# FALLBACK AUTOMÁTICO
# ============================================================
func _generate_steps_bbcode_filtered(recipe: RecipeResource, variants: Array) -> String:
	var excluded := _excluded_ids_from_variants(variants)
	var lines := []

	for req in recipe.ingredient_requirements:
		if req == null or excluded.has(req.ingredient_id):
			continue

		var ing_data := Managers.ingredient_database.get_ingredient(req.ingredient_id)
		var name := _get_display_name(req.ingredient_id)

		if req.stages.size() > 0:
			for s in req.stages:
				var verb := _verb_for_stage(s, req, ing_data)
				if verb == "" : verb = "Usar"
				lines.append("[color=%s]- %s %s[/color]" % [TEXT_COLOR, verb, name])
		else:
			var v := _verb_for_state(req.state, req, ing_data)
			if v == "" : v = "Usar"
			lines.append("[color=%s]- %s %s[/color]" % [TEXT_COLOR, v, name])

	if lines.is_empty():
		lines.append("[color=%s]- Preparar e servir os ingredientes.[/color]" % TEXT_COLOR)

	lines.append("")
	lines.append("[color=%s][i]Montar no prato e servir ao cliente.[/i][/color]" % LIGHT_TEXT_COLOR)

	return "[color=%s]Modo de preparo:[/color]\n%s" % [SECTION_COLOR, "\n".join(lines)]


# ============================================================
# HELPERS
# ============================================================
func _excluded_ids_from_variants(variants: Array) -> Array:
	var out := []
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
			if "arroz" in req.ingredient_id: return "Adicionar"
			if "feijao" in req.ingredient_id or "feijão" in req.ingredient_id: return "Adicionar"
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
	if data and str(data.initial_state) == needed:
		return true

	if (data == null or data.initial_state == "") and Managers:
		var check := Managers.ingredient_database.get_ingredient(req.ingredient_id)
		if check and str(check.initial_state) == needed:
			return true

	if req and req.has_meta("initial_state") and str(req.get_meta("initial_state")) == needed:
		return true

	return false


func _get_display_name(id: String) -> String:
	var d := Managers.ingredient_database.get_ingredient(id)
	if d and d.display_name != "":
		return d.display_name
	return id.capitalize()


func _get_ingredient_icon_bbcode(id: String, state: String) -> String:
	# tenta pegar mini icon considerando estado; managers retorna Texture2D ou null
	var tex := Managers.ingredient_database.get_mini_icon(id, state)
	if tex == null:
		return ""
	var path := tex.resource_path
	if path == "":
		return ""
	# 14px costuma encaixar com texto
	return "[img=14]" + path + "[/img]"


# ============================================================
# INTERAÇÃO / ANIMAÇÕES
# ============================================================
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

	content_box.visible = true
	scroll.modulate.a = 1.0

	# atualiza conteúdo e espera o layout estabilizar antes de medir
	_update_content()
	await get_tree().process_frame
	await get_tree().process_frame

	var content_h := content_box.get_combined_minimum_size().y + HEADER_EXTRA
	var target_h := int(clamp(content_h, MIN_HEIGHT, MAX_HEIGHT))

	# garante que o scroll tenha o tamanho correto ANTES da animação (evita "texto descendo antes do fundo")
	scroll.custom_minimum_size = Vector2(OPEN_WIDTH - INNER_HORIZONTAL_PADDING, max(1, target_h - HEADER_EXTRA))

	var tw := create_tween()
	tw.parallel().tween_property(note_bg, "custom_minimum_size", Vector2(OPEN_WIDTH, target_h), 0.35).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(scroll, "custom_minimum_size", Vector2(OPEN_WIDTH - INNER_HORIZONTAL_PADDING, target_h - HEADER_EXTRA), 0.35)
	await tw.finished

	scroll.scroll_vertical = 0


func _animate_close() -> void:
	if not is_open:
		return
	is_open = false

	var tw := create_tween()
	tw.parallel().tween_property(note_bg, "custom_minimum_size", CLOSED_SIZE, 0.3)
	tw.parallel().tween_property(scroll, "custom_minimum_size", Vector2(OPEN_WIDTH - INNER_HORIZONTAL_PADDING, CLOSED_SIZE.y), 0.3)
	await tw.finished

	content_box.visible = false
