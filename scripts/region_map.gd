extends Node2D
class_name RegionMap

signal closed()

## Exports (arraste texturas no Inspector)
@export var player_icon_texture: Texture2D
@export var background_texture: Texture2D

# visual tweaks
@export var outline_scale: Vector2 = Vector2(1.06, 1.06)
@export var overlay_alpha: float = 0.7

# Internals (tipados)
var _region_areas: Dictionary[String, Area2D] = {}        # region_id -> Area2D node
var _locks: Dictionary[String, Sprite2D] = {}            # region_id -> lock Sprite2D
var _selected_region: String = ""
var _hover_region: String = ""
var _popup_region: String = ""

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var map_node: Node2D = $MapNode
@onready var player_icon: Sprite2D = $MapNode/PlayerIcon
@onready var locks_container: Node2D = $LocksContainer
@onready var popup_locked: Control = $PopupLockedRegion

func _ready() -> void:
	# overlay setup
	dark_overlay.color = Color(0, 0, 0, overlay_alpha)

	# Background texture opcional (se existir)
	if background_texture and map_node.has_node("Background"):
		var bg_node: Node = map_node.get_node("Background")
		if bg_node is Sprite2D:
			(bg_node as Sprite2D).texture = background_texture

	_discover_regions()
	_update_visuals()
	popup_locked.visible = false
	self.visible = false

	# conectar botões do popup se existirem
	if popup_locked.has_node("ButtonClose"):
		var btn_close: Button = popup_locked.get_node("ButtonClose") as Button
		if not btn_close.is_connected("pressed", Callable(self, "_on_popup_close")):
			btn_close.pressed.connect(_on_popup_close)
	if popup_locked.has_node("ButtonUnlock"):
		var btn_unlock: Button = popup_locked.get_node("ButtonUnlock") as Button
		if not btn_unlock.is_connected("pressed", Callable(self, "_on_popup_unlock_pressed")):
			btn_unlock.pressed.connect(_on_popup_unlock_pressed)


# --- Descobre dinamicamente os Area2D e locks ---
func _discover_regions() -> void:
	_region_areas.clear()
	_locks.clear()

	# procura por filhos Area2D no MapNode
	var children: Array = map_node.get_children()
	for child in children:
		var child_node: Node = child as Node
		if child_node is Area2D:
			# prefere caso o node seja RegionArea (classe)
			if child_node is RegionArea:
				var ra: RegionArea = child_node as RegionArea
				var rid: String = ra.region_id if ra.region_id != "" else ""
				if rid != "":
					_region_areas[rid] = ra
			else:
				# fallback: checar metadados
				if child_node.has_meta("region_id"):
					var rid_meta: String = str(child_node.get_meta("region_id"))
					if rid_meta != "":
						_region_areas[rid_meta] = child_node as Area2D

	# locks: filho de LocksContainer com nome "Lock_<region_id>"
	for lock_child in locks_container.get_children():
		if lock_child is Sprite2D:
			var lock_sprite: Sprite2D = lock_child as Sprite2D
			var name: String = lock_sprite.name
			if name.begins_with("Lock_"):
				var rid_from_name: String = name.replace("Lock_", "")
				_locks[rid_from_name] = lock_sprite

	# conecta sinais das áreas (dinamicamente)
	for rid in _region_areas.keys():
		var area: Area2D = _region_areas[rid]
		# conectar sinais RegionArea se disponíveis
		if area.has_signal("region_clicked"):
			if not area.is_connected("region_clicked", Callable(self, "_on_region_clicked")):
				area.connect("region_clicked", Callable(self, "_on_region_clicked"))
		else:
			# fallback - conectar input_event para captura
			if not area.is_connected("input_event", Callable(self, "_on_area_input_event")):
				area.connect("input_event", Callable(self, "_on_area_input_event"))

		if area.has_signal("region_hovered"):
			if not area.is_connected("region_hovered", Callable(self, "_on_region_hover")):
				area.connect("region_hovered", Callable(self, "_on_region_hover"))
		if area.has_signal("region_exited"):
			if not area.is_connected("region_exited", Callable(self, "_on_region_exit")):
				area.connect("region_exited", Callable(self, "_on_region_exit"))


# --- Abre e fecha o mapa (pausa) ---
func open() -> void:
	self.visible = true
	# pausar tree (faça a pausa do jogo)
	get_tree().paused = true
	_update_visuals()

func close() -> void:
	self.visible = false
	get_tree().paused = false
	_selected_region = ""
	_hover_region = ""
	emit_signal("closed")


# fallback click quando Area2D não emitiu region_clicked
func _on_area_input_event(viewport: Viewport, event: InputEvent, shape_idx: int, area: Object) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# tentar descobrir region_id
		var rid: String = ""
		if area is RegionArea:
			rid = (area as RegionArea).region_id
		elif (area as Node).has_meta("region_id"):
			rid = str((area as Node).get_meta("region_id"))
		if rid != "":
			_on_region_clicked(rid)


# --- handlers para sinais das RegionArea ---
func _on_region_clicked(region_id: String) -> void:
	var rm := Managers.region_manager
	if not rm.is_unlocked(region_id):
		_show_locked(region_id)
		return

	# marcar para viajar no próximo dia
	_selected_region = region_id
	rm.request_region_change_next_day(region_id)
	_update_visuals()


func _on_region_hover(region_id: String) -> void:
	_hover_region = region_id
	_update_visuals()


func _on_region_exit(region_id: String) -> void:
	if _hover_region == region_id:
		_hover_region = ""
	_update_visuals()


# --- Visual update (outline, locks, player icon) ---
func _update_visuals() -> void:
	var rm := Managers.region_manager
	var current_region: String = rm.current_region_id

	# locks
	for rid in _locks.keys():
		var lock_sprite: Sprite2D = _locks[rid]
		lock_sprite.visible = not rm.is_unlocked(rid)

	# region area visuals
	for rid in _region_areas.keys():
		var area: Area2D = _region_areas[rid]
		var sprite_node: Sprite2D = area.get_node_or_null("Sprite") as Sprite2D
		var outline_node: Sprite2D = area.get_node_or_null("Outline") as Sprite2D
		if outline_node:
			outline_node.visible = (rid == _hover_region) or (rid == _selected_region)
			outline_node.scale = outline_scale
		if sprite_node:
			if rid == _selected_region:
				sprite_node.modulate = Color(1, 1, 1, 1)
			elif rid == current_region:
				sprite_node.modulate = Color(1, 1, 1, 0.95)
			else:
				sprite_node.modulate = Color(1, 1, 1, 0.85)

	# player icon (pos)
	if player_icon_texture:
		player_icon.texture = player_icon_texture

	var current_reg: RegionResource = rm.get_current_region()
	if current_reg != null and _region_areas.has(rm.current_region_id):
		var area_node: Area2D = _region_areas[rm.current_region_id]
		var anchor_node: Node2D = area_node.get_node_or_null("PlayerAnchor") as Node2D
		if anchor_node:
			player_icon.global_position = anchor_node.global_position
		else:
			var s: Sprite2D = area_node.get_node_or_null("Sprite") as Sprite2D
			if s and s.texture:
				var size: Vector2 = s.texture.get_size() * s.scale
				# Sprite pivot center: compute approximate center
				player_icon.global_position = s.global_position
		player_icon.visible = true
	else:
		player_icon.visible = false


# --- LOCKED popup ---
func _show_locked(region_id: String) -> void:
	_popup_set_region(region_id)
	popup_locked.visible = true

func _popup_set_region(region_id: String) -> void:
	_popup_region = region_id
	var r: RegionResource = Managers.region_manager.get_region(region_id)
	if r == null:
		return
	# preencher UI (procura Title / Description dentro do Control)
	if popup_locked.has_node("Title"):
		var lbl_title: Label = popup_locked.get_node("Title") as Label
		lbl_title.text = r.display_name
	if popup_locked.has_node("Description"):
		var lbl_desc: RichTextLabel = popup_locked.get_node("Description") as RichTextLabel if popup_locked.get_node("Description") is RichTextLabel else null
		if lbl_desc:
			lbl_desc.clear()
			lbl_desc.append_bbcode("[b]Preço:[/b] M$ %d\n\n%s" % [r.unlock_price, r.description])
		else:
			var lbl_desc2: Label = popup_locked.get_node_or_null("Description") as Label
			if lbl_desc2:
				lbl_desc2.text = "Preço: M$ %d\n\n%s" % [r.unlock_price, r.description]


func _on_popup_close() -> void:
	popup_locked.visible = false


func _on_popup_unlock_pressed() -> void:
	if _popup_region == "":
		return
	var rm := Managers.region_manager
	if money_can_unlock(_popup_region):
		if rm.unlock_region(_popup_region):
			# opcional: subtrair dinheiro da MainScene
			var main: MainScene = get_tree().current_scene as MainScene
			if main:
				main.add_money(-rm.get_region(_popup_region).unlock_price)
			popup_locked.visible = false
			_update_visuals()
	else:
		push_warning("Dinheiro insuficiente para desbloquear %s" % _popup_region)


func money_can_unlock(region_id: String) -> bool:
	var r: RegionResource = Managers.region_manager.get_region(region_id)
	if r == null:
		return false
	var main: MainScene = get_tree().current_scene as MainScene
	if main == null:
		return false
	return main.money >= int(r.unlock_price)


# input - fechar clicando fora (usa o Background do MapNode quando existir)
func _input(event: InputEvent) -> void:
	if not self.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = event.position
		# tenta obter rect do mapa via MapNode/Background (se existir)
		var bg_node: Sprite2D = map_node.get_node_or_null("Background") as Sprite2D
		if bg_node and bg_node.texture:
			var size: Vector2 = bg_node.texture.get_size() * bg_node.scale
			var map_rect: Rect2 = Rect2(bg_node.global_position - (size * 0.5), size)
			if not map_rect.has_point(click_pos):
				close()
		else:
			# fallback: se não tem Background definido, não fecha ao clicar (ou pode fechar se quiser)
			pass


func _on_blocker_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()
