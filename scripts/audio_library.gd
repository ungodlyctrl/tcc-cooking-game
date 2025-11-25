extends Resource
class_name AudioLibrary

@export_group("BGM – Música do Jogo")
@export var bgm_main: AudioEntry
@export var bgm_cutscene: AudioEntry
@export var bgm_end_of_day: AudioEntry

@export_group("Ambience – Sons Ambiente")
@export var ambience_street_tracks: Array[AudioEntry] = []
@export var ambience_kitchen_hum: AudioEntry
@export var ambience_night: AudioEntry

@export_group("SFX – Interface e Interações")
@export var ui_click: AudioEntry
@export var ui_toggle_panel: AudioEntry
@export var ui_error: AudioEntry

@export_group("SFX – Ingredientes")
@export var ingredient_pick: AudioEntry
@export var ingredient_drop: AudioEntry
@export var ingredient_trash: AudioEntry

@export_group("SFX – Prato (Plate)")
@export var plate_pick: AudioEntry
@export var plate_drop: AudioEntry

@export_group("SFX – Bowl")
@export var bowl_pick: AudioEntry
@export var bowl_drop: AudioEntry

@export_group("SFX – Minigame de Corte")
@export var cutgame_start: AudioEntry
@export var cut_slices: Array[AudioEntry] = []

@export_group("SFX – Fogão / Panela / Fritura")
@export var stove_place_pan: AudioEntry
@export var stove_place_fryer: AudioEntry
@export var sfx_fry_loop: AudioEntry
@export var sfx_boiling_loop: AudioEntry

@export_group("SFX - Cliente")
@export var bad_reaction: AudioEntry
@export var good_reaction: AudioEntry
@export var new_client: AudioEntry
