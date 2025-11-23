# RegionArea.gd
extends Area2D
class_name RegionArea

@export var region_id: String = ""    # exemplo: "nordeste", "sudeste"

signal region_clicked(region_id: String)
signal region_hovered(region_id: String)
signal region_exited(region_id: String)

func _ready() -> void:
	pass

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("region_clicked", region_id)

func _on_mouse_entered() -> void:
	emit_signal("region_hovered", region_id)

func _on_mouse_exited() -> void:
	emit_signal("region_exited", region_id)


# conecte os sinais do próprio Area2D (usando o editor):
# - mouse_entered -> _on_mouse_entered
# - mouse_exited  -> _on_mouse_exited
