extends Node

# Arraste os sprites dos clientes aqui no Inspector
@export var client_sprites: Array[Texture2D] = []

func _ready() -> void:
	if client_sprites.is_empty():
		push_warning("⚠️ ClientManager: nenhuma sprite configurada em client_sprites.")
	else:
		print("ClientManager carregou %d sprites" % client_sprites.size())

func pick_random_sprite() -> Texture2D:
	if client_sprites.is_empty():
		return null
	return client_sprites.pick_random()
