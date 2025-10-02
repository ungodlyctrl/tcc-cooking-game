extends Control
class_name PrepArea

# ---------------- Config ----------------
@export var slot_scene: PackedScene = preload("res://scenes/ui/container_slot.tscn")
@export var prep_layouts: Array[PrepLayoutResource] = []   # <<< arraste seus 3 .tres aqui
@export var end_margin: float = 20.0

# Plate config
@export var plate_scene: PackedScene = preload("res://scenes/ui/drop_plate_area.tscn")
@export var plate_early_pos: Vector2 = Vector2(304, 192)  # dias 1..4
@export var plate_late_pos: Vector2 = Vector2(384, 192)   # dia >= threshold_day
@export var plate_threshold_day: int = 5

# ---------------- Refs ----------------
@onready var fundo: NinePatchRect = $Fundo
@onready var slots_parent: Control = $SlotsParent
@onready var utensils_parent: Control = $UtensilsParent

# ---------------- Vars ----------------
var current_plate: Node = null

# ---------------- Public ----------------
func update_ingredients_for_day(current_day: int) -> void:
	clear_day_leftovers()
	var chosen_preset: PrepLayoutResource = _find_best_preset_for_day(current_day)
	if chosen_preset:
		await _apply_preset(chosen_preset, current_day)
	call_deferred("_reflow")
	ensure_plate_for_day(current_day)


func clear_day_leftovers() -> void:
	if current_plate and current_plate.is_inside_tree():
		current_plate.queue_free()
	current_plate = null

	for s in slots_parent.get_children():
		if s is Control:
			s.queue_free()
	# utensílios não são apagados


# ---------------- Internals ----------------
func ensure_plate_for_day(current_day: int) -> void:
	var target_world_pos: Vector2 = plate_early_pos if current_day < plate_threshold_day else plate_late_pos

	if current_plate and current_plate.is_inside_tree():
		if current_plate is Control:
			current_plate.anchor_left = 0
			current_plate.anchor_top = 0
			current_plate.anchor_right = 0
			current_plate.anchor_bottom = 0
		current_plate.position = target_world_pos - utensils_parent.position
		return

	if plate_scene == null:
		push_warning("PrepArea: plate_scene não está definido.")
		return

	var plate_node := plate_scene.instantiate()
	if plate_node == null:
		push_warning("PrepArea: falha ao instanciar plate_scene.")
		return

	if plate_node is Control:
		plate_node.anchor_left = 0
		plate_node.anchor_top = 0
		plate_node.anchor_right = 0
		plate_node.anchor_bottom = 0
	plate_node.position = target_world_pos - utensils_parent.position

	utensils_parent.add_child(plate_node)
	current_plate = plate_node


func _find_best_preset_for_day(current_day: int) -> PrepLayoutResource:
	var best: PrepLayoutResource = null
	for pr in prep_layouts:
		if pr and pr.min_day <= current_day:
			if best == null or pr.min_day > best.min_day:
				best = pr
	return best


func _apply_preset(preset: PrepLayoutResource, current_day: int) -> void:
	# garante que o ingredient_database existe
	if Managers.ingredient_database == null:
		await get_tree().process_frame
		if Managers.ingredient_database == null:
			push_error("❌ IngredientDatabase não inicializado!")
			return

	for se in preset.slots:
		if se == null or se.ingredient_id == "":
			continue
		var data: IngredientData = Managers.ingredient_database.get_ingredient(se.ingredient_id)
		if data == null or current_day < data.min_day:
			continue
		_instantiate_slot(se.ingredient_id, se.pos, se.size)

	for ue in preset.utensils:
		if ue == null or ue.node_name == "":
			continue
		var target: Control = utensils_parent.get_node_or_null(ue.node_name)
		if target == null:
			continue
		target.anchor_left = 0
		target.anchor_top = 0
		target.anchor_right = 0
		target.anchor_bottom = 0
		target.position = ue.pos - utensils_parent.position
		if ue.size != Vector2.ZERO:
			target.custom_minimum_size = ue.size
		target.visible = ue.visible
		# marque como fixo (se necessário)
		target.set_meta("is_fixed", true)


func _instantiate_slot(ingredient_id: String, pos: Vector2, size: Vector2) -> void:
	if slot_scene == null: return
	var slot_node := slot_scene.instantiate()
	if slot_node == null: return

	if slot_node.has_method("set"):
		slot_node.set("ingredient_id", ingredient_id)

	slot_node.anchor_left = 0
	slot_node.anchor_top = 0
	slot_node.anchor_right = 0
	slot_node.anchor_bottom = 0
	slot_node.position = pos - slots_parent.position
	slot_node.custom_minimum_size = size if size != Vector2.ZERO else Vector2(64, 64)

	slots_parent.add_child(slot_node)


func _reflow() -> void:
	await get_tree().process_frame

	var max_x: float = 0.0
	var max_y: float = 0.0

	for s in slots_parent.get_children():
		if not (s is Control): continue
		var s_size: Vector2 = s.custom_minimum_size
		if s_size.x <= 0 or s_size.y <= 0:
			s_size = s.get_combined_minimum_size()
		max_x = max(max_x, s.position.x + s_size.x)
		max_y = max(max_y, s.position.y + s_size.y)

	for u in utensils_parent.get_children():
		if not (u is Control): continue
		var u_size: Vector2 = u.custom_minimum_size
		if u_size.x <= 0 or u_size.y <= 0:
			u_size = u.get_combined_minimum_size()
		max_x = max(max_x, u.position.x + u_size.x)
		max_y = max(max_y, u.position.y + u_size.y)

	var total_w: float = max(max_x + end_margin, 640)
	var total_h: float = max(max_y, 360)

	fundo.custom_minimum_size = Vector2(total_w, total_h)
	custom_minimum_size = Vector2(total_w, total_h)

	var parent_modeprep := get_parent().get_parent()
	if parent_modeprep is ModePreparation:
		parent_modeprep._update_scroll_area()
