extends Node

var recipe_paths: Array = []

func _ready():
	load_all_recipes("res://resources/recipes")  # ou o caminho onde você salva suas receitas

func load_all_recipes(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") and not dir.current_is_dir():
				var full_path = path + "/" + file_name
				recipe_paths.append(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
		print("📦 Receitas encontradas:", recipe_paths)
	else:
		print("❌ Pasta de receitas não encontrada:", path)

func get_random_recipe() -> Resource:
	if recipe_paths.is_empty():
		print("⚠️ Nenhuma receita carregada!")
		return null
	var path = recipe_paths.pick_random()
	return load(path)
