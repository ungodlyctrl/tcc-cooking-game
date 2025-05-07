extends Panel
@onready var dialogue_label = $MarginContainer/Label

func _ready():
	await get_tree().process_frame
	$DialogueBox.custom_minimum_size = $DialogueBox/MarginContainer/Label.get_minimum_size()
