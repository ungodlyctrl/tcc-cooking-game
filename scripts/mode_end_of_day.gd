extends Control


func _on_next_day_button_pressed() -> void:
	get_tree().current_scene.start_new_day()
