extends Node

## Lista de todos os clientes configurados no Inspector
@export var clients: Array[ClientData] = []

## recent_clients por região
## Exemplo:
## {
##    "sudeste": ["cliente1_path", "cliente3_path"],
##    "nordeste": ["cliente5_path"]
## }
var recent_by_region: Dictionary = {}

const RECENT_LIMIT: int = 3


# ---------------- READY ----------------
func _ready() -> void:
	if clients.is_empty():
		push_warning("⚠️ ClientManager: nenhum cliente configurado.")
	else:
		print("ClientManager carregou %d clientes" % clients.size())



func pick_random_client(region_id: String) -> ClientData:
	# 1) filtra por região
	var pool: Array[ClientData] = []
	for c in clients:
		if c.region == region_id:
			pool.append(c)

	# 2) fallback se não há clientes daquela região
	if pool.is_empty():
		push_warning("⚠️ Nenhum cliente da região '%s'. Usando fallback global." % region_id)
		return clients.pick_random()

	# 3) se só tem 1, retorna ele
	if pool.size() == 1:
		return pool[0]

	# 4) inicializa lista de recentes da região, se necessário
	if not recent_by_region.has(region_id):
		recent_by_region[region_id] = []

	var recent_list: Array = recent_by_region[region_id]
	var available: Array[ClientData] = []

	# 5) evitar repetições com base em resource_path
	for c in pool:
		var id := c.resource_path
		if not recent_list.has(id):
			available.append(c)

	# 6) se todos já são "recentes", libera tudo novamente
	if available.is_empty():
		recent_list.clear()
		available = pool.duplicate()

	# 7) escolha um cliente disponível
	var chosen: ClientData = available.pick_random()
	var chosen_id := chosen.resource_path

	# 8) registra no histórico
	recent_list.append(chosen_id)
	if recent_list.size() > RECENT_LIMIT:
		recent_list.pop_front()

	recent_by_region[region_id] = recent_list

	return chosen
