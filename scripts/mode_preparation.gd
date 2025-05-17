extends Control
class_name ModePreparation

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var prep_area: Control = $ScrollContainer/PrepArea
@onready var fundo: TextureRect = $ScrollContainer/PrepArea/Fundo
@onready var drop_plate_area := $ScrollContainer/PrepArea/DropPlateArea
@onready var finish_button := $HUDPrep/FinishButton


# Configurações de scroll horizontal
const SCROLL_MARGIN: int = 50
const SCROLL_SPEED: float = 400.0

var max_scroll: int = 0
var dragging: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	await get_tree().process_frame  # Espera um frame pra garantir que a textura foi carregada
	_update_prep_area_size()
	_update_scroll_limits()
	

func _update_prep_area_size() -> void:
	if fundo.texture is Texture2D:
		var size := fundo.texture.get_size()
		prep_area.custom_minimum_size = size
		print("Max scroll calculado:", max_scroll)


func _process(delta: float) -> void:
	
	# Se está arrastando algo → ativa scroll automático com mouse nas bordas
	if DragManager.current_drag_type == DragManager.DragType.INGREDIENT:
		var mouse_x := get_viewport().get_mouse_position().x
		var screen_width := get_viewport().get_visible_rect().size.x
		var scroll_val := scroll_container.scroll_horizontal

		if mouse_x >= screen_width - SCROLL_MARGIN:
			scroll_val += SCROLL_SPEED * delta
		elif mouse_x <= SCROLL_MARGIN:
			scroll_val -= SCROLL_SPEED * delta

		scroll_container.scroll_horizontal = clamp(scroll_val, 0, max_scroll)
	else:
		# Se não está arrastando, apenas limita o scroll manual
		scroll_container.scroll_horizontal = clamp(scroll_container.scroll_horizontal, 0, max_scroll)


func _gui_input(event: InputEvent) -> void:
	# Bloqueia scroll manual se estiver arrastando algo
	if DragManager.current_drag_type != DragManager.DragType.NONE:
		dragging = false
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			last_mouse_pos = event.position
		else:
			dragging = false

	elif event is InputEventMouseMotion and dragging:
		var delta: Vector2 = event.relative
		scroll_container.scroll_horizontal -= delta.x


func _update_scroll_limits() -> void:
	# Garante que o scroll respeite o tamanho do fundo
	if fundo.texture is Texture2D:
		var fundo_width: int = fundo.texture.get_width()
		var visible_width: int = scroll_container.size.x
		max_scroll = max(fundo_width - visible_width, 0)


func _on_finish_button_pressed() -> void:
	# Finaliza pedido e volta pro modo atendimento
	get_tree().current_scene.add_money(20)
	get_tree().current_scene.switch_mode(0)
