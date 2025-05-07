extends Resource
class_name Recipe

@export var name: String = ""
@export var region: String = ""
@export var ingredients_required: Array[String] = []
@export var steps: Array[String] = []
@export var dialog_lines: Array[String] = []

# Opcional: minigames associados
@export var minigames: Array[String] = []
