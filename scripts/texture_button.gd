extends TextureRect

@export var action: String = ""  ## "play", "options", "quit"

# cores
const NORMAL_COLOR := Color(1, 1, 1)
const HOVER_COLOR := Color("#fe7ac5")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate = NORMAL_COLOR

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_sfx(AudioManager.library.ui_click)
		_do_action()
		

func _do_action():
	var menu := get_tree().current_scene
	if not menu:
		return
	
	match action:
		"play":
			menu.start_game()
		"options":
			menu.toggle_options()
		"quit":
			menu.quit_game()

func _on_mouse_entered():
	modulate = HOVER_COLOR

func _on_mouse_exited():
	modulate = NORMAL_COLOR
