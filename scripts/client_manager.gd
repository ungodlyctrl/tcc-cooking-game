extends Node

## Lista de clientes (arraste ClientData.tres aqui no Inspector)
@export var clients: Array[ClientData] = []

var last_index: int = -1

func _ready() -> void:
	if clients.is_empty():
		push_warning("⚠️ ClientManager: nenhum ClientData configurado.")
	else:
		print("ClientManager carregou %d clientes" % clients.size())

func pick_random_client() -> ClientData:
	if clients.is_empty():
		return null
	if clients.size() == 1:
		return clients[0]

	var index := randi_range(0, clients.size() - 1)
	while index == last_index:
		index = randi_range(0, clients.size() - 1)

	last_index = index
	return clients[index]
