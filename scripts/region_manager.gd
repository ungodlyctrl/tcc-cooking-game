extends Node
class_name RegionManager

signal region_unlocked(region_id: String)
signal region_selected(region_id: String)

@export var region_resources: Array[RegionResource] = []

var regions: Dictionary = {}                  # id -> RegionResource
var unlocked_regions: Dictionary = {}         # id -> bool
@export var current_region_id: String = "sudeste"
var pending_region_change: String = ""

func _ready() -> void:
	for r in region_resources:
		if r and r.id != "":
			regions[r.id] = r
			unlocked_regions[r.id] = (r.id == "sudeste")  # apenas sudeste desbloqueado por padrão

	print("RegionManager carregou %d regiões" % regions.size())

func is_unlocked(region_id: String) -> bool:
	return unlocked_regions.get(region_id, false)

func unlock_region(region_id: String) -> bool:
	if not regions.has(region_id):
		return false
	if unlocked_regions.get(region_id, false):
		return false

	unlocked_regions[region_id] = true
	emit_signal("region_unlocked", region_id)
	print("🔓 Região desbloqueada:", region_id)
	return true

func select_region_now(region_id: String) -> bool:
	if not regions.has(region_id):
		return false
	if not is_unlocked(region_id):
		return false

	current_region_id = region_id
	emit_signal("region_selected", region_id)
	print("🌎 Região atual agora é:", region_id)
	return true

func request_region_change_next_day(region_id: String) -> bool:
	if not regions.has(region_id):
		return false
	if not is_unlocked(region_id):
		return false

	pending_region_change = region_id
	return true

func apply_pending_change() -> void:
	if pending_region_change != "":
		current_region_id = pending_region_change
		emit_signal("region_selected", current_region_id)
		print("➡ Mudança de região aplicada no novo dia:", current_region_id)
		pending_region_change = ""

func get_region(id: String) -> RegionResource:
	return regions.get(id, null)

func get_current_region() -> RegionResource:
	return get_region(current_region_id)
