extends Control
class_name PrepArea

# configuração
@export var slot_scene: PackedScene = preload("res://scenes/ui/container_slot.tscn")
@export var layouts_folder: String = "res://resources/prep_layouts"
@export var end_margin: float = 20.0   ## margem extra depois do último elemento

# refs
@onready var fundo: NinePatchRect = $Fundo
@onready var slots_parent: Control = $SlotsParent
@onready var utensils_parent: Control = $UtensilsParent

func _ready() -> void:
	_clear_slots()

func update_ingredients_for_day(current_day: int) -> void:
	_clear_slots()
	var chosen_preset: Resource = _find_best_preset_for_day(current_day)
	if chosen_preset and chosen_preset is PrepLayoutResource:
		_apply_preset(chosen_preset as PrepLayoutResource, current_day)
	call_deferred("_reflow")

func _clear_slots() -> void:
	for child in slots_parent.get_children():
		child.queue_free()

func _find_best_preset_for_day(current_day: int) -> PrepLayoutResource:
	var best: PrepLayoutResource = null
	var dir := DirAccess.open(layouts_folder)
	if dir == null:
		push_warning("PrepArea: não foi possível abrir pasta de layouts: %s" % layouts_folder)
		return null

	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if fname.to_lower().ends_with(".tres"):
			var path := layouts_folder
			if not path.ends_with("/"):
				path += "/"
			path += fname
			var res: Resource = load(path)
			if res is PrepLayoutResource:
				var pr := res as PrepLayoutResource
				if pr.min_day <= current_day:
					if best == null or pr.min_day > best.min_day:
						best = pr
		fname = dir.get_next()
	dir.list_dir_end()
	return best

func _apply_preset(preset: PrepLayoutResource, current_day: int) -> void:
	# slots
	for se in preset.slots:
		if se == null or se.ingredient_id == "":
			continue
		var data: IngredientData = IngredientDatabase.get_ingredient(se.ingredient_id)
		if data == null:
			continue
		if current_day < data.min_day:
			continue
		_instantiate_slot(se.ingredient_id, se.pos, se.size)

	# utensílios
	for ue in preset.utensils:
		if ue == null or ue.node_name == "":
			continue
		var target: Control = utensils_parent.get_node_or_null(ue.node_name)
		if target == null:
			for c in utensils_parent.get_children():
				if c is Control and c.name == ue.node_name:
					target = c
					break
		if target:
			target.anchor_left = 0
			target.anchor_top = 0
			target.anchor_right = 0
			target.anchor_bottom = 0
			target.position = ue.pos - utensils_parent.position
			if ue.size != Vector2.ZERO:
				target.custom_minimum_size = ue.size
			target.visible = ue.visible

func _instantiate_slot(ingredient_id: String, pos: Vector2, size: Vector2) -> void:
	if slot_scene == null:
		return
	var slot_node := slot_scene.instantiate()
	if slot_node == null:
		return

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

	# mede slots
	for s in slots_parent.get_children():
		if not (s is Control):
			continue
		var s_size: Vector2 = s.custom_minimum_size
		if s_size.x <= 0 or s_size.y <= 0:
			s_size = s.get_combined_minimum_size()
		var right: float = s.position.x + s_size.x
		var bottom: float = s.position.y + s_size.y
		max_x = max(max_x, right)
		max_y = max(max_y, bottom)

	# mede utensílios
	for u in utensils_parent.get_children():
		if not (u is Control):
			continue
		var u_size: Vector2 = u.custom_minimum_size
		if u_size.x <= 0 or u_size.y <= 0:
			u_size = u.get_combined_minimum_size()
		var right: float = u.position.x + u_size.x
		var bottom: float = u.position.y + u_size.y
		max_x = max(max_x, right)
		max_y = max(max_y, bottom)

	# aplica margem extra
	var total_w: float = max(max_x + end_margin, 640)
	var total_h: float = max(max_y, 360)

	fundo.custom_minimum_size = Vector2(total_w, total_h)
	custom_minimum_size = Vector2(total_w, total_h)

	# força atualização do scroll no ModePreparation
	var parent_modeprep := get_parent().get_parent()
	if parent_modeprep is ModePreparation:
		parent_modeprep._update_scroll_area()
