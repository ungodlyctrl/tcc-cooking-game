extends Node

@export var library: AudioLibrary

@onready var bgm: AudioStreamPlayer = $BGM
@onready var ambience: AudioStreamPlayer = $Ambience
@onready var sfx: AudioStreamPlayer = $SFX

var ambience_playing := false

func _ready():
	bgm.bus = "Music"
	ambience.bus = "Ambience"
	sfx.bus = "SFX"


# =====================================================
# INTERNAL — helper
# =====================================================
func _apply_entry(player: AudioStreamPlayer, entry: AudioEntry) -> void:
	if entry == null:
		return
	player.stream = entry.stream
	player.volume_db = entry.volume_db
	player.pitch_scale = entry.pitch_scale


# =====================================================
# BGM
# =====================================================
func play_bgm(entry: AudioEntry):
	if entry == null:
		return
	_apply_entry(bgm, entry)
	bgm.play()

func play_bgm_fade(entry: AudioEntry, fade_time := 1.0):
	if entry == null:
		return

	var tween := create_tween()
	tween.tween_property(bgm, "volume_db", -40.0, fade_time * 0.5)
	await tween.finished

	_apply_entry(bgm, entry)
	bgm.play()

	var tween2 := create_tween()
	tween2.tween_property(bgm, "volume_db", entry.volume_db, fade_time * 0.5)

func stop_bgm():
	bgm.stop()


# =====================================================
# AMBIENCE
# =====================================================
func play_ambience_random(entries: Array[AudioEntry]):
	if entries.is_empty():
		return
	
	if ambience_playing:
		return

	ambience_playing = true

	var entry: AudioEntry = entries.pick_random()
	_apply_entry(ambience, entry)

	# ponto aleatório
	var len := entry.stream.get_length()
	var offset := randf() * len

	ambience.play(offset)

func stop_ambience():
	ambience.stop()
	ambience_playing = false

	
func stop_ambience_fade(fade_time := 0.8):
	if not ambience.playing:
		return
	var tween := create_tween()
	tween.tween_property(ambience, "volume_db", ambience.volume_db - 20.0, fade_time)
	await tween.finished
	ambience.stop()
	ambience_playing = false


# =====================================================
# SFX
# =====================================================
func play_sfx(entry: AudioEntry, random_pitch := true):
	if entry == null:
		return

	# não chamar _apply_entry por causa do pitch
	sfx.stream = entry.stream
	sfx.volume_db = entry.volume_db
	
	if random_pitch:
		sfx.pitch_scale = entry.pitch_scale * randf_range(0.95, 1.04)
	else:
		sfx.pitch_scale = entry.pitch_scale

	# faz interrupção do som anterior para evitar overlap
	sfx.stop()
	sfx.play()




# SFX com variação (corte)
func play_sfx_variants(entries: Array[AudioEntry]):
	if entries.is_empty():
		return

	var e: AudioEntry = entries.pick_random()
	play_sfx(e)


# loops (fritura/cozimento)
func play_loop_sfx(entry: AudioEntry):
	_apply_entry(ambience, entry)
	ambience.play()

func stop_loop_sfx():
	ambience.stop()
