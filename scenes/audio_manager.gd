extends Node

@export var library: AudioLibrary

@onready var bgm: AudioStreamPlayer = $BGM
@onready var ambience: AudioStreamPlayer = $Ambience
@onready var sfx: AudioStreamPlayer = $SFX

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

	var entry: AudioEntry = entries.pick_random()
	_apply_entry(ambience, entry)

	# ponto aleatório
	var len := entry.stream.get_length()
	var offset := randf() * len

	ambience.play(offset)

func stop_ambience():
	ambience.stop()


# =====================================================
# SFX
# =====================================================
func play_sfx(entry: AudioEntry, random_pitch := true):
	if entry == null:
		return
	_apply_entry(sfx, entry)

	if random_pitch:
		sfx.pitch_scale = entry.pitch_scale * randf_range(0.95, 1.05)

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
