extends Panel

@onready var label := $MarginContainer/RichTextLabel

func _ready():
	await get_tree().process_frame
	adjust_to_content()

func adjust_to_content():
	var text_size = label.get_combined_minimum_size()
	custom_minimum_size = text_size + Vector2(10, 10) # margem
