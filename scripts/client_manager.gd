extends Node

## Lista de clientes (arraste ClientData.tres aqui no Inspector)
@export var clients: Array[ClientData] = []

## Guarda os últimos clientes mostrados (para evitar repetições)
var recent_clients: Array[int] = []
const RECENT_LIMIT: int = 3  # quantidade de clientes que devem ser diferentes antes de repetir

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

	var available_indices: Array[int] = []
	for i in range(clients.size()):
		if not recent_clients.has(i):
			available_indices.append(i)

	# Se todos já apareceram recentemente, limpa a lista e recomeça
	if available_indices.is_empty():
		recent_clients.clear()
		for i in range(clients.size()):
			available_indices.append(i)

	var index : int = available_indices.pick_random()
	recent_clients.append(index)

	# Mantém o histórico no tamanho máximo
	if recent_clients.size() > RECENT_LIMIT:
		recent_clients.pop_front()

	return clients[index]
