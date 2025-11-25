extends Node
class_name MixManager

@export var mix_list: Array[MixResource] = []
var mixes: Dictionary = {}

func _ready() -> void:
	mixes.clear()
	for m in mix_list:
		if m and m.mix_id != "":
			mixes[m.mix_id] = m
	print("🔧 MixManager carregou %d mixes." % mixes.size())


func try_get_mix(ingredients: Array[Dictionary]) -> Dictionary:
	for mix_id in mixes.keys():
		var mix: MixResource = mixes[mix_id]

		if _matches_mix(mix, ingredients):
			return _build_mix_item(mix, ingredients)

	return {}  # nenhum mix


func _matches_mix(mix: MixResource, ingredients: Array[Dictionary]) -> bool:
	if mix.required_ingredients.size() != ingredients.size():
		return false

	var needed := mix.required_ingredients.duplicate(true)
	var provided := ingredients.duplicate(true)

	for ing in provided:
		var matched := false

		for need in needed:
			if need.ingredient_id == ing["id"] and need.state == ing["state"]:
				needed.erase(need)
				matched = true
				break

		if not matched:
			return false

	return needed.is_empty()


func _build_mix_item(mix: MixResource, source_ingredients: Array[Dictionary]) -> Dictionary:
	return {
		"type": "mixed",
		"mix_id": mix.mix_id,
		"sprite": mix.final_sprite,
		"ingredients": source_ingredients.duplicate(true)
	}
