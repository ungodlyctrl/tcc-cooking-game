extends Control

@onready var drop_area := $ScrollContainer/PrepArea/DropArea
@onready var finalizar_button := $HUD/FinishButton

func _on_finish_button_pressed() -> void:
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
var scroll_speed := 600  # velocidade da rolagem

func _gui_input(event):
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
	#parte da limitação do scroll até o fundo
	if fundo.texture is Texture2D:
		var fundo_largura = fundo.texture.get_width()
		var visivel_largura = scroll_container.size.x
		var max_scroll = max(fundo_largura - visivel_largura, 0)
		scroll_container.scroll_horizontal = clamp(scroll_container.scroll_horizontal, 0, max_scroll)

	#parte de arrastar com ingrediente
	if not DragManager.is_dragging_ingredient:
		return

	var mouse_x = get_viewport().get_mouse_position().x
	var screen_width = get_viewport().size.x

	var scroll = scroll_container.scroll_horizontal
	var max_scroll = scroll_container.get_h_scroll_bar().max_value

	if mouse_x > screen_width - scroll_margin:
		scroll += scroll_speed * delta
	elif mouse_x < scroll_margin:
		scroll -= scroll_speed * delta

	scroll_container.scroll_horizontal = clamp(scroll, 0, max_scroll)
