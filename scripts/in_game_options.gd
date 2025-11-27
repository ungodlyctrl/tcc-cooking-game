extends Control

@onready var slider_master   = $OptionsPanel/SliderMaster
@onready var slider_music    = $OptionsPanel/SliderMusic
@onready var slider_sfx      = $OptionsPanel/SliderSFX
@onready var slider_ambience = $OptionsPanel/SliderAmbience
@onready var panel = $OptionsPanel
@onready var overlay = $DarkOverlay

func _ready():
		# Carrega valores ao abrir o painel
	slider_master.value   = AudioSettings.master
	slider_music.value    = AudioSettings.music
	slider_sfx.value      = AudioSettings.sfx
	slider_ambience.value = AudioSettings.ambience
	hide()

func _on_SliderMaster_value_changed(v): 
	AudioSettings.set_master(v)
func _on_SliderMusic_value_changed(v): 
	AudioSettings.set_music(v)
func _on_SliderSFX_value_changed(v): 
	AudioSettings.set_sfx(v)
func _on_SliderAmbience_value_changed(v): 
	AudioSettings.set_ambience(v)

func _on_continue_button_pressed():
	hide()
	get_tree().paused = false

func _on_back_to_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/gamemodes/main_menu.tscn")
