extends Control
class_name RecipeNotePanel

## Painel que exibe o nome, ingredientes e modo de preparo da receita.
## Pode ser aberto/fechado com clique e aparece automaticamente apenas
## na primeira receita do primeiro dia.

@onready var note_bg: NinePatchRect = $NoteBackground
@onready var scroll: ScrollContainer = $NoteBackground/MarginContainer/ScrollContainer
@onready var content_box: VBoxContainer = $NoteBackground/MarginContainer/ScrollContainer/ContentBox
@onready var title_label: RichTextLabel = $NoteBackground/MarginContainer/ScrollContainer/ContentBox/RecipeTitle
@onready var ingredient_label: RichTextLabel = $NoteBackground/MarginContainer/ScrollContainer/ContentBox/IngredientList
@onready var steps_label: RichTextLabel = $NoteBackground/MarginContainer/ScrollContainer/ContentBox/PreparationSteps

var current_recipe: RecipeResource = null
var current_variants: Array = []

# tamanhos e limites visuais
const CLOSED_SIZE: Vector2 = Vector2(180, 10)
const OPEN_WIDTH: int = 180
const MIN_HEIGHT: int = 120
const MAX_HEIGHT: int = 360

# Use cor escura para garantir legibilidade sobre background claro
const TITLE_BBCODE := "[font_size=16][color=#2b1a10][b]%s[/b][/color][/font_size]\n"
const SECTION_COLOR := "#2b1a10"  # cor para os headers/texto

var is_open: bool = false

# ---------------------------------------------------------
# Inicialização
# ---------------------------------------------------------
func _ready() -> void:
	await get_tree().process_frame  # garante que nós filhos estejam prontos

	# Configura labels com segurança
	for lbl in [title_label, ingredient_label, steps_label]:
		if lbl and lbl is RichTextLabel:
			lbl.bbcode_enabled = true
			lbl.scroll_active = false
			lbl.visible_characters = -1  # garante renderização total
			lbl.bbcode_text = ""         # limpa texto com segurança
		else:
			push_warning("⚠️ Um dos labels não é RichTextLabel ou ainda não inicializou.")

	# Começa visível e fechado — mostrando a “pontinha” da nota (visível)
	note_bg.custom_minimum_size = CLOSED_SIZE
	note_bg.modulate.a = 1.0
	visible = true
	is_open = false

	# Posição fixa no canto superior direito da tela (ajusta no editor se precisar)
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	position = Vector2(450, 0)

	# Clique do usuário → abrir/fechar
	note_bg.gui_input.connect(_on_note_gui_input)

	print("🟢 RecipeNotePanel pronto — posição:", position, " | tamanho:", CLOSED_SIZE)



# ---------------------------------------------------------
# Define a receita atual e mostra conteúdo
# ---------------------------------------------------------
func set_recipe(recipe: RecipeResource, variants: Array = []) -> void:
	current_recipe = recipe
	current_variants = variants.duplicate(true)
	print("🧾 Enviando receita para RecipeNotePanel:", current_recipe.recipe_name if current_recipe else "<null>")
	_update_content()

	# Garante visibilidade (mantém pontinha visível)
	if not visible:
		visible = true
		var tw = create_tween()
		tw.tween_property(note_bg, "modulate:a", 1.0, 0.35)


# ---------------------------------------------------------
# Atualiza o conteúdo textual
# ---------------------------------------------------------
func _update_content() -> void:
	print("📋 Atualizando conteúdo da nota — receita:", current_recipe)
	if current_recipe == null:
		print("⚠️ Nenhuma receita recebida!")
		title_label.bbcode_text = ""
		ingredient_label.bbcode_text = ""
		steps_label.bbcode_text = ""
		return

	# debug info (útil)
	print("🔍 Nome:", current_recipe.recipe_name)
	print("🔍 Ingredientes:", current_recipe.ingredient_requirements)
	print("🔍 Display Steps:", current_recipe.display_steps if "display_steps" in current_recipe else [])

	# Título
	title_label.bbcode_text = TITLE_BBCODE % current_recipe.recipe_name

	# Ingredientes (com cor)
	var lines: Array[String] = []
	for req in current_recipe.ingredient_requirements:
		if req == null:
			continue
		var display := _get_display_name(req.ingredient_id)
		var qty := int(req.quantity)
		var qty_text := "" if qty <= 1 else " x%d" % qty
		lines.append("- %s%s" % [display, qty_text])
	var ing_block := "[color=%s][b]Ingredientes:[/b][/color]\n" % SECTION_COLOR
	ing_block += "\n".join(lines)
	ingredient_label.bbcode_text = ing_block

	# Etapas (display_steps tem precedência)
	if "display_steps" in current_recipe and current_recipe.display_steps and current_recipe.display_steps.size() > 0:
		var steps: Array[String] = []
		var excluded_ids := _excluded_ids_from_variants(current_variants)
		for s in current_recipe.display_steps:
			if not _line_mentions_excluded(s, excluded_ids):
				steps.append("- %s" % s)
		var steps_block := "[color=%s][b]Modo de preparo:[/b][/color]\n" % SECTION_COLOR
		steps_block += "\n".join(steps)
		steps_label.bbcode_text = steps_block
	else:
		steps_label.bbcode_text = _generate_steps_bbcode_filtered(current_recipe, current_variants)

	# Força redraw / recalcula layout no próximo frame (importante para get_combined_minimum_size)
	await get_tree().process_frame
	await get_tree().process_frame  # às vezes precisa de 2 frames para o layout estabilizar


# ---------------------------------------------------------
# Gera texto automático de etapas
# ---------------------------------------------------------
func _generate_steps_bbcode_filtered(recipe: RecipeResource, variants: Array) -> String:
	print("🧩 Gerando texto automático de etapas...")
	var excluded_ids := _excluded_ids_from_variants(variants)
	var step_lines: Array[String] = []

	print("➡️ Ingredientes da receita:", recipe.ingredient_requirements)
	print("➡️ Variants recebidas:", variants)

	for req in recipe.ingredient_requirements:
		if req == null:
			print("⚠️ Ingrediente nulo encontrado, ignorando.")
			continue
		if excluded_ids.has(req.ingredient_id):
			print("⏭️ Ignorando ingrediente (variant exclui):", req.ingredient_id)
			continue

		var ing_data: IngredientData = null
		if Managers and Managers.ingredient_database:
			ing_data = Managers.ingredient_database.get_ingredient(req.ingredient_id)
		var display := _get_display_name(req.ingredient_id)

		# Garante que sempre teremos uma linha textual
		if req.stages and req.stages.size() > 0:
			for s in req.stages:
				var verb := _verb_for_stage(s, req, ing_data)
				if verb == "":
					verb = "Usar"
				step_lines.append("- %s %s" % [verb, display])
		else:
			var v := _verb_for_state(req.state, req, ing_data)
			if v == "" or v == null:
				v = "Usar"
			step_lines.append("- %s %s" % [v, display])

	# Se por algum motivo nada foi adicionado, ainda mostra algo
	if step_lines.is_empty():
		step_lines.append("- Preparar e servir os ingredientes.")

	step_lines.append("")  # linha em branco para separar
	step_lines.append("[i]Montar no prato e servir ao cliente.[/i]")

	print("🧾 Linhas geradas para nota:", step_lines)
	var block := "[color=%s][b]Modo de preparo:[/b][/color]\n" % SECTION_COLOR
	block += "\n".join(step_lines)
	return block


# ---------------------------------------------------------
# Utilidades para variações de receita
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
		if eid == "":
			continue
		var dname := _get_display_name(eid).to_lower()
		if eid.to_lower() in line.to_lower() or dname in line.to_lower():
			return true
	return false


# ---------------------------------------------------------
# Verbos automáticos por etapa/estado
# ---------------------------------------------------------
func _verb_for_stage(stage_value: int, req: IngredientRequirement, ing_data: IngredientData) -> String:
	match stage_value:
		IngredientRequirement.Stage.COOKING:
			if _ingredient_is_in_state(ing_data, "cooked"): return "Adicionar"
			return "Cozinhar"
		IngredientRequirement.Stage.FRYING:
			var idlow := req.ingredient_id.to_lower()
			if "pao" in idlow or "pão" in idlow or "bread" in idlow: return "Tostar"
			if "queijo" in idlow or "cheese" in idlow: return "Dourar / Derreter"
			return "Fritar"
		IngredientRequirement.Stage.CUTTING:
			if _ingredient_is_in_state(ing_data, "cut"): return "Adicionar"
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
		"raw": return "Adicionar cru"
		_: return "Usar"


# ---------------------------------------------------------
# Auxiliares de ingrediente
# ---------------------------------------------------------
func _ingredient_is_in_state(ing_data: IngredientData, needed_state: String) -> bool:
	if ing_data == null:
		return false
	var s: String = str(ing_data.initial_state)
	if s == "":
		return false
	return s == needed_state

func _get_display_name(id: String) -> String:
	if Managers and Managers.ingredient_database:
		var d: IngredientData = Managers.ingredient_database.get_ingredient(id)
		if d and d.display_name != "":
			return d.display_name
	return id.capitalize()


# ---------------------------------------------------------
# Animações e interação
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

	# atualiza conteúdo (garante que o texto está pronto antes de calcular tamanho)
	_update_content()
	await get_tree().process_frame
	await get_tree().process_frame

	# calcula altura necessária a partir do content_box
	var content_h := content_box.get_combined_minimum_size().y + 28
	var target_h: int = clampi(int(content_h), MIN_HEIGHT, MAX_HEIGHT)
	var target_vec := Vector2(OPEN_WIDTH, target_h)

	# anima somente o custom_minimum_size do note_bg (topo está ancorado → expande para baixo)
	var tw := create_tween()
	tw.tween_property(note_bg, "custom_minimum_size", target_vec, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# garante alpha / visibilidade do fundo
	tw.tween_property(note_bg, "modulate:a", 1.0, 0.25)
	await tw.finished

	# Se o conteúdo for maior que o limite, ScrollContainer cuidará do scroll (automaticamente)
	# Força o scroll para o topo
	if scroll:
		scroll.scroll_vertical = 0


func _animate_close() -> void:
	if not is_open:
		return
	is_open = false

	var tw := create_tween()
	tw.tween_property(note_bg, "custom_minimum_size", CLOSED_SIZE, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# opcional: reduz alpha levemente para indicar "fechado", mas mantemos visível (pontinha)
	tw.tween_property(note_bg, "modulate:a", 1.0, 0.2)
	await tw.finished

	# deixa labels prontas mas o painel fica com tamanho fechado (pontinha visível)
