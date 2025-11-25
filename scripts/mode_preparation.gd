extends Control
class_name ModePreparation

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var prep_area: PrepArea = $ScrollContainer/PrepArea
@onready var recipe_note_panel: RecipeNotePanel = $HUDPrep/RecipeNotePanel

const SCROLL_MARGIN := 50
const SCROLL_SPEED := 400.0

var max_scroll := 0
var dragging := false
var last_mouse_pos := Vector2.ZERO
var current_recipe: RecipeResource = null
var _ready_finished := false


func _ready() -> void:
	await get_tree().process_frame
	_ready_finished = true

	_update_scroll_area()
	scroll_container.gui_input.connect(_on_scroll_gui_input)

	if recipe_note_panel:
		recipe_note_panel.visible = true

	if current_recipe:
		_set_drop_plate_recipe(current_recipe)


func _update_scroll_area() -> void:
	var fundo_width: int = int(prep_area.custom_minimum_size.x)
	var viewport_width := scroll_container.get_viewport_rect().size.x

	max_scroll = max(fundo_width - viewport_width, 0)
	scroll_container.scroll_horizontal = clamp(scroll_container.scroll_horizontal, 0, max_scroll)


func _process(delta: float) -> void:
	if DragManager.current_drag_type != DragManager.DragType.NONE:
		var mouse_x := get_viewport().get_mouse_position().x
		var screen_w := get_viewport().get_visible_rect().size.x

		var scroll_val := scroll_container.scroll_horizontal

		if mouse_x >= screen_w - SCROLL_MARGIN:
			scroll_val += SCROLL_SPEED * delta
		elif mouse_x <= SCROLL_MARGIN:
			scroll_val -= SCROLL_SPEED * delta

		scroll_container.scroll_horizontal = clamp(scroll_val, 0, max_scroll)


func _on_scroll_gui_input(event: InputEvent) -> void:
	if DragManager.current_drag_type != DragManager.DragType.NONE:
		dragging = false
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		last_mouse_pos = event.position

	elif event is InputEventMouseMotion and dragging:
		scroll_container.scroll_horizontal = clamp(
			scroll_container.scroll_horizontal - event.relative.x,
			0,
			max_scroll
		)


# ---------------- RECEITA ----------------
func set_recipe(recipe: RecipeResource, variants: Array = []) -> void:
	current_recipe = recipe

	if recipe_note_panel:
		recipe_note_panel.set_recipe(recipe, variants)

	if _ready_finished:
		_set_drop_plate_recipe(recipe)
	else:
		await ready
		_set_drop_plate_recipe(recipe)


func _set_drop_plate_recipe(recipe: RecipeResource) -> void:
	if not prep_area:
		push_warning("⚠ PrepArea não encontrado!")
		return

	var dpa: DropPlateArea = prep_area.get_node_or_null("UtensilsParent/DropPlateArea")

	if dpa:
		dpa.set_current_recipe(recipe)
		
	var bowl := prep_area.get_node_or_null("UtensilsParent/BowlArea")




# ---------------- UI Toggle Recipe Note ----------------
func _on_recipe_toggle_button_pressed() -> void:
	if recipe_note_panel and current_recipe:
		recipe_note_panel.set_recipe(current_recipe)
		recipe_note_panel._toggle_open()


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if recipe_note_panel and current_recipe:
			recipe_note_panel.set_recipe(current_recipe)
			recipe_note_panel._toggle_open()
