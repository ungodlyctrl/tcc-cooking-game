extends Control
class_name ModePreparation

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var prep_area: Control = $ScrollContainer/PrepArea
@onready var fundo: TextureRect = $ScrollContainer/PrepArea/Fundo
@onready var recipe_note_panel: RecipeNotePanel = $HUDPrep/RecipeNotePanel

const SCROLL_MARGIN := 50
const SCROLL_SPEED := 400.0

var max_scroll := 0
var dragging := false
var last_mouse_pos := Vector2.ZERO

func _ready() -> void:
	await get_tree().process_frame
	_update_scroll_area()

func _update_scroll_area() -> void:
	if fundo.texture is Texture2D:
		var fundo_width = fundo.texture.get_width()
		var viewport_width = scroll_container.get_viewport_rect().size.x

		# Define o tamanho fixo da área para forçar scroll
		prep_area.custom_minimum_size.x = fundo_width

		# Define o limite de scroll corretamente
		max_scroll = max(fundo_width - viewport_width, 0)

		# Garante que o scroll inicie em um valor válido
		scroll_container.scroll_horizontal = clamp(scroll_container.scroll_horizontal, 0, max_scroll)

func _process(delta: float) -> void:
	# Scroll automático nas bordas durante arraste
	if DragManager.current_drag_type == DragManager.DragType.INGREDIENT:
		var mouse_x = get_viewport().get_mouse_position().x
		var screen_width = get_viewport().get_visible_rect().size.x
		var scroll_val = scroll_container.scroll_horizontal

		if mouse_x >= screen_width - SCROLL_MARGIN:
			scroll_val += SCROLL_SPEED * delta
		elif mouse_x <= SCROLL_MARGIN:
			scroll_val -= SCROLL_SPEED * delta

		scroll_container.scroll_horizontal = clamp(scroll_val, 0, max_scroll)
	else:
		# Sem drag: mantém scroll dentro dos limites
		scroll_container.scroll_horizontal = clamp(scroll_container.scroll_horizontal, 0, max_scroll)

func _gui_input(event: InputEvent) -> void:
	if DragManager.current_drag_type != DragManager.DragType.NONE:
		dragging = false
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		last_mouse_pos = event.position
	elif event is InputEventMouseMotion and dragging:
		var delta = event.relative
		scroll_container.scroll_horizontal = clamp(
			scroll_container.scroll_horizontal - delta.x,
			0, max_scroll
		)


func set_recipe(recipe: RecipeResource) -> void:
	current_recipe = recipe


var current_recipe: RecipeResource
func _on_recipe_toggle_button_pressed() -> void:
	if recipe_note_panel and current_recipe:
		recipe_note_panel.show_recipe(current_recipe)
		recipe_note_panel.show()


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if recipe_note_panel and current_recipe:
			recipe_note_panel.show_recipe(current_recipe)
			recipe_note_panel.show()
