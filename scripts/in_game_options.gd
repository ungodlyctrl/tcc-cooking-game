extends Control

@onready var volume_slider = $OptionsPanel/VolumeSlider
@onready var panel = $OptionsPanel
@onready var overlay = $DarkOverlay

func _ready():
	hide()

func _on_volume_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_continue_button_pressed():
	hide()
	get_tree().paused = false

func _on_back_to_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/gamemodes/main_menu.tscn")
