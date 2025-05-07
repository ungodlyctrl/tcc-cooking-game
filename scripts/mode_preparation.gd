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

	
