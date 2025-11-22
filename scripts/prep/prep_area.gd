extends Control
class_name PrepArea

# ---------------- Config ----------------
@export var slot_scene: PackedScene = preload("res://scenes/ui/container_slot.tscn")
@export var end_margin: float = 20.0

# Plate config
@export var plate_scene: PackedScene = preload("res://scenes/ui/drop_plate_area.tscn")
@export var plate_early_pos: Vector2 = Vector2(304, 192)
@export var plate_late_pos: Vector2 = Vector2(384, 192)
@export var plate_threshold_day: int = 5

# ---------------- Refs ----------------
@onready var fundo: NinePatchRect = $Fundo
@onready var slots_parent: Control = $SlotsParent
@onready var utensils_parent: Control = $UtensilsParent

# ---------------- Vars ----------------
var current_plate: DropPlateArea = null
var _is_dragging_plate: bool = false
var region_resource: RegionResource = null


# ---------------- Region Setup ----------------
func set_region(region: RegionResource) -> void:
	region_resource = region

	# aplica layouts específicos
	if region != null:
		clear_day_leftovers()
		# layouts aplicados no update_ingredients_for_day
		pass


# ---------------- Public ----------------
func update_ingredients_for_day(current_day: int) -> void:
	if _is_dragging_plate:
		return

	clear_day_leftovers()

	var layout: PrepLayoutResource = _find_best_layout_for_region(current_day)
	if layout:
		await _apply_layout(layout, current_day)

	call_deferred("_reflow")
	ensure_plate_for_day(current_day)


func clear_day_leftovers() -> void:
	if _is_dragging_plate:
		return

	if current_plate and current_plate.is_inside_tree():
		current_plate.queue_free()

	current_plate = null

	for s in slots_parent.get_children():
		if s is Control:
			s.queue_free()


# ---------------- Layout ----------------
func _find_best_layout_for_region(current_day: int) -> PrepLayoutResource:
	if region_resource == null:
		return null

	var best: PrepLayoutResource = null

	for pr in region_resource.prep_layouts:
		if pr and pr.min_day <= current_day:
			if best == null or pr.min_day > best.min_day:
				best = pr

	return best


func _apply_layout(preset: PrepLayoutResource, current_day: int) -> void:
	if Managers.ingredient_database == null:
		await get_tree().process_frame
		if Managers.ingredient_database == null:
			push_error("❌ IngredientDatabase não inicializado!")
			return

	# SLOTS (ingredientes)
	for se in preset.slots:
		if se == null or se.ingredient_id == "":
			continue

		var data := Managers.ingredient_database.get_ingredient(se.ingredient_id)
		if data == null:
			continue

		if current_day < data.min_day:
			continue

		_instantiate_slot(se.ingredient_id, se.pos, se.size)

	# UTENSÍLIOS
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
		target.set_meta("is_fixed", true)


func _instantiate_slot(ingredient_id: String, pos: Vector2, size: Vector2) -> void:
	if slot_scene == null:
		return

	var slot := slot_scene.instantiate()
	if slot == null:
		return

	slot.set("ingredient_id", ingredient_id)

	slot.anchor_left = 0
	slot.anchor_top = 0
	slot.anchor_right = 0
	slot.anchor_bottom = 0

	slot.position = pos - slots_parent.position

	if size == Vector2.ZERO:
		slot.custom_minimum_size = Vector2(64, 64)
	else:
		slot.custom_minimum_size = size

	slots_parent.add_child(slot)


# ---------------- Plate ----------------
func ensure_plate_for_day(current_day: int) -> void:
	if _is_dragging_plate:
		return

	var target_world_pos: Vector2

	if current_day < plate_threshold_day:
		target_world_pos = plate_early_pos
	else:
		target_world_pos = plate_late_pos

	if current_plate and current_plate.is_inside_tree():
		current_plate.position = target_world_pos - utensils_parent.position
		return

	if plate_scene == null:
		push_warning("PrepArea: plate_scene não definido.")
		return

	var plate = plate_scene.instantiate()
	if plate == null:
		push_warning("PrepArea: falha ao instanciar plate_scene.")
		return

	plate.name = "DropPlateArea"
	plate.position = target_world_pos - utensils_parent.position
	utensils_parent.add_child(plate)

	current_plate = plate

	if current_plate.has_signal("drag_state_changed"):
		if current_plate.is_connected("drag_state_changed", Callable(self, "_on_plate_drag_state_changed")):
			current_plate.disconnect("drag_state_changed", Callable(self, "_on_plate_drag_state_changed"))

		current_plate.connect("drag_state_changed", Callable(self, "_on_plate_drag_state_changed"))


func _on_plate_drag_state_changed(is_dragging: bool) -> void:
	_is_dragging_plate = is_dragging

	if current_plate and current_plate.is_inside_tree():
		current_plate.visible = not is_dragging

	set_process(not is_dragging)


# ---------------- Layout Reflow ----------------
func _reflow() -> void:
	await get_tree().process_frame

	var max_x: float = 0.0
	var max_y: float = 0.0

	for s in slots_parent.get_children():
		if not (s is Control):
			continue

		var size = s.custom_minimum_size
		if size.x <= 0 or size.y <= 0:
			size = s.get_combined_minimum_size()

		max_x = max(max_x, s.position.x + size.x)
		max_y = max(max_y, s.position.y + size.y)

	for u in utensils_parent.get_children():
		if not (u is Control):
			continue

		var size = u.custom_minimum_size
		if size.x <= 0 or size.y <= 0:
			size = u.get_combined_minimum_size()

		max_x = max(max_x, u.position.x + size.x)
		max_y = max(max_y, u.position.y + size.y)

	var total_w = max(max_x + end_margin, 640)
	var total_h = max(max_y, 325)

	fundo.custom_minimum_size = Vector2(total_w, total_h)
	custom_minimum_size = Vector2(total_w, total_h)

	var parent_mode := get_parent().get_parent()
	if parent_mode is ModePreparation:
		parent_mode._update_scroll_area()
