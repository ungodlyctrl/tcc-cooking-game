extends Control

@onready var drop_area := $ScrollContainer/PrepArea/DropPlateArea
@onready var finalizar_button := $HUDPrep/FinishButton


func _on_finish_button_pressed() -> void:
	get_tree().current_scene.add_money(20)
	get_tree().current_scene.switch_mode(0)

#Tudo sobre o scroll da tela
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var preparea: Control = $ScrollContainer/PrepArea
@onready var fundo: TextureRect = $ScrollContainer/PrepArea/Fundo
@onready var scroll := $ScrollContainer

var max_scroll := 0
var dragging := false
var last_mouse_pos := Vector2.ZERO
var scroll_margin := 50  # margem da tela onde começa a rolagem
var scroll_speed := 400  # velocidade da rolagem

func _gui_input(event: InputEvent) -> void:
	# ⛔ Bloqueia o scroll manual se estiver arrastando algo
	if DragManager.current_drag_type != DragManager.DragType.NONE:
		dragging = false  # Garante que nada fique "preso"
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			last_mouse_pos = event.position
		else:
			dragging = false

	elif event is InputEventMouseMotion and dragging:
		var delta = event.relative
		scroll_container.scroll_horizontal -= delta.x

func _process(delta):
	# Atualiza o max_scroll uma única vez corretamente
	if fundo.texture is Texture2D:
		var fundo_largura = fundo.texture.get_width()
		var visivel_largura = scroll_container.size.x
		max_scroll = max(fundo_largura - visivel_largura, 0)

	# Se não está arrastando nada, apenas limita o scroll atual (não faz scroll automático)
	if DragManager.current_drag_type != DragManager.DragType.INGREDIENT:
		scroll_container.scroll_horizontal = clamp(scroll_container.scroll_horizontal, 0, max_scroll)
		return

	var mouse_x = get_viewport().get_mouse_position().x
	var screen_width = get_viewport().get_visible_rect().size.x

	var scroll_val = scroll_container.scroll_horizontal

	if mouse_x >= screen_width - scroll_margin:
		scroll_val += scroll_speed * delta
	elif mouse_x <= scroll_margin:
		scroll_val -= scroll_speed * delta

	scroll_container.scroll_horizontal = clamp(scroll_val, 0, max_scroll)
