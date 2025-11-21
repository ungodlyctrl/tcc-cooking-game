extends Control

## ------------------------- NODES -------------------------
@onready var options_panel: Control = $OptionsPanel
@onready var credits_panel: Control = $CreditsPanel
@onready var volume_slider: HSlider = $OptionsPanel/VolumeSlider
@onready var overlay: Control = $OverlayDarkener
@onready var logo: TextureRect = $Logo


## ------------------------- STATE -------------------------
var _time: float = 0.0
var _base_pos: Vector2


## ------------------------- READY -------------------------
func _ready() -> void:
	options_panel.visible = false
	credits_panel.visible = false
	overlay.visible = false

	# Salva posição inicial da logo
	_base_pos = logo.position

	# Garantir animação natural
	logo.pivot_offset = logo.size / 2.0


## ------------------------- PROCESS (ANIMAÇÃO LOGO) -------------------------
func _process(delta: float) -> void:
	_time += delta

	# --- Respiração (scale suave) ---
	var breath: float = 1.0 + sin(_time * 0.7) * 0.02  # ±2%
	logo.scale = Vector2(breath, breath)

	# --- Micro flutuação vertical/horizontal ---
	var float_y: float = sin(_time * 0.5) * 1.0     # ±2px
	var float_x: float = sin(_time * 0.7 ) * 1.0  # ±1px
	logo.position = _base_pos + Vector2(float_x, float_y)

	# --- Tilt super leve (orgânico) ---
	var tilt: float = sin(_time * 1.0) * deg_to_rad(0.8)
	logo.rotation = tilt


## ------------------------- BUTTON ACTIONS -------------------------
func start_game() -> void:
	var scene := load("res://scenes/intro_cutscene.tscn")
	var cutscene = scene.instantiate()
	get_tree().root.add_child(cutscene)

	# esconde o menu enquanto a cutscene roda
	self.visible = false

	cutscene.connect("cutscene_finished", Callable(self, "_on_cutscene_end"))


func _on_cutscene_end() -> void:
	get_tree().change_scene_to_file("res://scenes/main_scene.tscn")


func toggle_options() -> void:
	options_panel.visible = not options_panel.visible
	credits_panel.visible = false
	overlay.visible = options_panel.visible


func toggle_credits() -> void:
	credits_panel.visible = not credits_panel.visible
	options_panel.visible = false
	overlay.visible = credits_panel.visible


func quit_game() -> void:
	get_tree().quit()


## ------------------------- UI / INPUT -------------------------
func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(value)
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_hide_all_panels()


func _hide_all_panels() -> void:
	options_panel.visible = false
	credits_panel.visible = false
	overlay.visible = false
