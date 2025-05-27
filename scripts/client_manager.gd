extends Node

var client_sprites: Array[Texture2D] = []

func _ready() -> void:
	_load_client_sprites()

func _load_client_sprites() -> void:
	client_sprites.clear()
	var dir := DirAccess.open("res://assets/clients")

	if not dir:
		push_error("❌ Não foi possível abrir a pasta de clientes.")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".png"):
			var texture := load("res://assets/clients/" + file_name)
			if texture:
				client_sprites.append(texture)
		file_name = dir.get_next()

	dir.list_dir_end()

	if client_sprites.is_empty():
		push_warning("⚠️ Nenhuma sprite de cliente encontrada.")
