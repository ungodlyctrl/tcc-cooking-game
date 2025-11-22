extends Node

@export var clients: Array[ClientData] = []

var recent_clients: Array[int] = []
const RECENT_LIMIT: int = 3

func _ready() -> void:
	if clients.is_empty():
		push_warning("⚠️ ClientManager: nenhum cliente configurado.")
	else:
		print("ClientManager carregou %d clientes" % clients.size())

func pick_random_client(region_id: String = "") -> ClientData:
	if clients.is_empty():
		return null

	# Filtragem por região
	var pool: Array[ClientData] = []
	for c in clients:
		if region_id == "" or c.region == region_id:
			pool.append(c)

	if pool.is_empty():
		# fallback total
		return clients.pick_random()

	if pool.size() == 1:
		return pool[0]

	# Agora evitamos repetições COM BASE NO POOL
	var available: Array[ClientData] = []
	for c in pool:
		if not recent_clients.has(c.get_instance_id()):
			available.append(c)

	if available.is_empty():
		recent_clients.clear()
		available = pool.duplicate()

	var chosen = available.pick_random()
	recent_clients.append(chosen.get_instance_id())

	if recent_clients.size() > RECENT_LIMIT:
		recent_clients.pop_front()

	return chosen
