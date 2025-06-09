extends Control

@onready var options_panel = $OptionsPanel
@onready var credits_panel = $CreditsPanel
@onready var volume_slider = $OptionsPanel/VolumeSlider
@onready var overlay = $OverlayDarkener

func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	
	
func _ready():
	options_panel.visible = false
	credits_panel.visible = false

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_scene.tscn")

func _on_options_button_pressed():
	options_panel.visible = not options_panel.visible
	credits_panel.visible = false
	overlay.visible = true

func _on_credits_button_pressed():
	credits_panel.visible = not credits_panel.visible
	options_panel.visible = false
	overlay.visible = true

func _on_quit_button_pressed():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_hide_all_panels()


func _on_button_pressed() -> void:
	_hide_all_panels()
	
	
func _hide_all_panels():
	options_panel.visible = false
	credits_panel.visible = false
	overlay.visible = false
