extends Node

## Banco de dados global de ingredientes.
## Carrega todos os recursos do tipo IngredientData encontrados
## na pasta `res://resources/ingredients/`.
##
## Esse script deve estar configurado como Autoload no projeto.

var ingredients: Dictionary[String, IngredientData] = {}


func _ready() -> void:
	## Carrega os ingredientes automaticamente ao iniciar o jogo
	_load_ingredients()


func _load_ingredients() -> void:
	## Lê todos os arquivos `.tres` da pasta de ingredientes e
	## armazena no dicionário `ingredients`, indexados pelo id.
	var dir := DirAccess.open("res://resources/ingredients/")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var data: IngredientData = load("res://resources/ingredients/" + file_name)
				if data and data.id != "":
					ingredients[data.id] = data
			file_name = dir.get_next()


func get_ingredient(id: String) -> IngredientData:
	## Retorna o recurso IngredientData associado ao id.
	return ingredients.get(id, null)


func get_sprite(id: String, state: String) -> Texture2D:
	## Retorna a textura do ingrediente em um determinado estado.
	var data := get_ingredient(id)
	if data:
		return data.states.get(state, null)
	return null
