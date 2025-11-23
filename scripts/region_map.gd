extends Control
class_name RegionMap

signal closed()

## Exports (arraste texturas no Inspector)
@export var player_icon_texture: Texture2D
@export var background_texture: Texture2D

# visual tweaks
@export var outline_scale: Vector2 = Vector2(1.06, 1.06)
@export var overlay_alpha: float = 0.7

# Internals
var _region_areas: Dictionary[String, Area2D] = {}
var _locks: Dictionary[String, Sprite2D] = {}
var _selected_region: String = ""
var _hover_region: String = ""
var _popup_region: String = ""

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var map_node: Node2D = $MapNode
@onready var player_icon: Sprite2D = $MapNode/PlayerIcon
@onready var locks_container: Node2D = $LocksContainer
@onready var popup_locked: Control = $PopupLockedRegion


# ============================================================
# READY
# ============================================================
func _ready() -> void:
	# overlay setup
	dark_overlay.color = Color(0, 0, 0, overlay_alpha)

	# background opcional
	if background_texture and map_node.has_node("Background"):
		var bg_node := map_node.get_node("Background")
		if bg_node is Sprite2D:
			bg_node.texture = background_texture

	_discover_regions()
	_update_visuals()

	popup_locked.visible = false
	self.visible = false

	# ---------------------------------------------------------
	# NOVO: suporte aos novos botões em NinePatchRect
	# ---------------------------------------------------------
	var close_btn := popup_locked.get_node_or_null("CloseButton")
	if close_btn:
		close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		close_btn.gui_input.connect(_on_close_button_gui_input)

	var unlock_btn := popup_locked.get_node_or_null("UnlockButton")
	if unlock_btn:
		unlock_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		unlock_btn.gui_input.connect(_on_unlock_button_gui_input)


# ============================================================
# DESCOBRIR REGIÕES
# ============================================================
func _discover_regions() -> void:
	_region_areas.clear()
	_locks.clear()

	# identifica regions no MapNode
	for child in map_node.get_children():
		if child is Area2D:
			if child is RegionArea:
				var rid := (child as RegionArea).region_id
				if rid != "":
					_region_areas[rid] = child
			elif child.has_meta("region_id"):
				var rid_meta := str(child.get_meta("region_id"))
				if rid_meta != "":
					_region_areas[rid_meta] = child

	# locks em LocksContainer
	for lk in locks_container.get_children():
		if lk is Sprite2D:
			if lk.name.begins_with("Lock_"):
				var rid := lk.name.replace("Lock_", "")
				_locks[rid] = lk

	# conectar sinais
	for rid in _region_areas.keys():
		var area: Area2D = _region_areas[rid]

		if area.has_signal("region_clicked"):
			if not area.is_connected("region_clicked", Callable(self, "_on_region_clicked")):
				area.connect("region_clicked", Callable(self, "_on_region_clicked"))
		else:
			if not area.is_connected("input_event", Callable(self, "_on_area_input_event")):
				area.connect("input_event", Callable(self, "_on_area_input_event"))

		if area.has_signal("region_hovered"):
			if not area.is_connected("region_hovered", Callable(self, "_on_region_hover")):
				area.connect("region_hovered", Callable(self, "_on_region_hover"))

		if area.has_signal("region_exited"):
			if not area.is_connected("region_exited", Callable(self, "_on_region_exit")):
				area.connect("region_exited", Callable(self, "_on_region_exit"))


# ============================================================
# ABRIR / FECHAR MAPA
# ============================================================
func open() -> void:
	self.visible = true
	get_tree().paused = true
	_update_visuals()

	# impede DialogueBox de capturar clique
	var main := get_tree().current_scene as MainScene
	if main and main.mode_attendance:
		if main.mode_attendance.dialogue_box:
			main.mode_attendance.dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE


func close() -> void:
	self.visible = false
	get_tree().paused = false

	_selected_region = ""
	_hover_region = ""
	emit_signal("closed")

	# restaura DialogueBox
	var main := get_tree().current_scene as MainScene
	if main and main.mode_attendance:
		if main.mode_attendance.dialogue_box:
			main.mode_attendance.dialogue_box.mouse_filter = Control.MOUSE_FILTER_STOP


# ============================================================
# INPUT REGION FALLBACK
# ============================================================
func _on_area_input_event(viewport: Viewport, event: InputEvent, shape_idx: int, area: Object) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var rid := ""
		if area is RegionArea:
			rid = area.region_id
		elif (area as Node).has_meta("region_id"):
			rid = str((area as Node).get_meta("region_id"))

		if rid != "":
			_on_region_clicked(rid)


# ============================================================
# REGION HANDLERS
# ============================================================
func _on_region_clicked(region_id: String) -> void:
	var rm := Managers.region_manager

	# já está nessa região → ignorar
	if region_id == rm.current_region_id:
		return

	# região bloqueada → abre popup
	if not rm.is_unlocked(region_id):
		_show_locked(region_id)
		return

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


# ============================================================
# VISUALS
# ============================================================
func _update_visuals() -> void:
	var rm := Managers.region_manager
	var current_region := rm.current_region_id

	# locks visíveis p/ regiões fechadas
	for rid in _locks.keys():
		_locks[rid].visible = not rm.is_unlocked(rid)

	# visuais das regiões
	for rid in _region_areas.keys():
		var area := _region_areas[rid]
		var sprite := area.get_node_or_null("Sprite") as Sprite2D
		var outline := area.get_node_or_null("Outline") as Sprite2D

		if outline:
			outline.visible = (rid == _hover_region or rid == _selected_region)
			outline.scale = outline_scale

		if sprite:
			if rid == _selected_region:
				sprite.modulate = Color(1, 1, 1, 1)
			elif rid == current_region:
				sprite.modulate = Color(1, 1, 1, 0.95)
			else:
				sprite.modulate = Color(1, 1, 1, 0.85)

	# player icon
	if player_icon_texture:
		player_icon.texture = player_icon_texture

	if rm.get_current_region() and _region_areas.has(current_region):
		var area := _region_areas[current_region]
		var anchor := area.get_node_or_null("PlayerAnchor") as Node2D

		if anchor:
			player_icon.global_position = anchor.global_position
		else:
			var s := area.get_node_or_null("Sprite") as Sprite2D
			if s and s.texture:
				player_icon.global_position = s.global_position

		player_icon.visible = true
	else:
		player_icon.visible = false


# ============================================================
# POPUP LOCKED
# ============================================================
func _show_locked(region_id: String) -> void:
	_popup_set_region(region_id)
	popup_locked.visible = true


func _popup_set_region(region_id: String) -> void:
	_popup_region = region_id
	var r := Managers.region_manager.get_region(region_id)
	if r == null: return

	if popup_locked.has_node("Title"):
		popup_locked.get_node("Title").text = r.display_name

	if popup_locked.has_node("Description"):
		var desc := popup_locked.get_node("Description")
		if desc is RichTextLabel:
			desc.clear()
			desc.append_bbcode("[b]Preço:[/b] M$ %d\n\n%s" % [r.unlock_price, r.description])
		elif desc is Label:
			desc.text = "Preço: M$ %d\n\n%s" % [r.unlock_price, r.description]


func _on_popup_close() -> void:
	popup_locked.visible = false


func _on_popup_unlock_pressed() -> void:
	if _popup_region == "":
		return

	var rm := Managers.region_manager
	if money_can_unlock(_popup_region):
		if rm.unlock_region(_popup_region):
			var main := get_tree().current_scene as MainScene
			if main:
				main.add_money(-rm.get_region(_popup_region).unlock_price)
			popup_locked.visible = false
			_update_visuals()
	else:
		push_warning("Dinheiro insuficiente para desbloquear %s" % _popup_region)


func money_can_unlock(region_id: String) -> bool:
	var r := Managers.region_manager.get_region(region_id)
	if r == null:
		return false

	var main := get_tree().current_scene as MainScene
	if main == null:
		return false

	return main.money >= int(r.unlock_price)


# ============================================================
# INPUT – fechar ao clicar fora
# ============================================================
func _input(event: InputEvent) -> void:
	if not self.visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = event.position
		var bg := map_node.get_node_or_null("Background") as Sprite2D

		if bg and bg.texture:
			var size := bg.texture.get_size() * bg.scale
			var rect := Rect2(bg.global_position - size * 0.5, size)
			if not rect.has_point(click_pos):
				close()


# ============================================================
# NinePatchRect button handlers
# ============================================================
func _on_close_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_popup_close()


func _on_unlock_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_popup_unlock_pressed()
