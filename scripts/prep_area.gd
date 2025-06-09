extends Control

func clear_day_leftovers() -> void:
	for child in get_children():
		if child.is_in_group("day_temp"):
			child.queue_free()
