extends Node

# Valores em linear (0.0–1.0)
var master := 1.0
var music := 1.0
var sfx := 1.0
var ambience := 1.0

const SAVE_PATH := "user://audio_settings.cfg"

func _ready():
	load_settings()
	apply_all()

# -------------------------
# APLICAÇÃO
# -------------------------
func apply_all():
	_set_bus("Master", master)
	_set_bus("Music", music)
	_set_bus("SFX", sfx)
	_set_bus("Ambience", ambience)

func _set_bus(bus_name: String, value: float):
	var idx := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	AudioServer.set_bus_mute(idx, value <= 0.001)

# -------------------------
# MUDANÇAS DE VOLUME
# -------------------------
func set_master(v: float):
	master = clamp(v, 0.0, 1.0)
	_set_bus("Master", master)
	save_settings()

func set_music(v: float):
	music = clamp(v, 0.0, 1.0)
	_set_bus("Music", music)
	save_settings()

func set_sfx(v: float):
	sfx = clamp(v, 0.0, 1.0)
	_set_bus("SFX", sfx)
	save_settings()

func set_ambience(v: float):
	ambience = clamp(v, 0.0, 1.0)
	_set_bus("Ambience", ambience)
	save_settings()

# -------------------------
# SALVAR / CARREGAR
# -------------------------
func save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master", master)
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "ambience", ambience)
	cfg.save(SAVE_PATH)

func load_settings():
	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err != OK:
		return
	master = cfg.get_value("audio", "master", 1.0)
	music = cfg.get_value("audio", "music", 1.0)
	sfx = cfg.get_value("audio", "sfx", 1.0)
	ambience = cfg.get_value("audio", "ambience", 1.0)
