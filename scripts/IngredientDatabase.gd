extends Node

# Dicionário com informações dos ingredientes.
# Cada ingrediente tem um nome de exibição, uma sprite de container e, opcionalmente, estados visuais (raw, cut, cooked, etc.).
const DATA := {
	"batata": {
		"display_name": "Batata",
		"container": "res://assets/ingredientes/batata/container.png",
		"states": {
			"raw": "res://assets/ingredientes/batata/raw.png",
			"cut": "res://assets/ingredientes/batata/cut.png",
			"cooked": "res://assets/ingredientes/batata/cooked.png",
			"fried": "res://assets/ingredientes/batata/fried.png"
		}
	},
	"carne": {
		"display_name": "Carne",
		"container": "res://assets/ingredientes/carne/container.png",
		"states": {
			"raw": "res://assets/ingredientes/carne/raw.png",
			"cut": "res://assets/ingredientes/carne/cut.png",
			"cooked": "res://assets/ingredientes/carne/cooked.png",
			"fried": "res://assets/ingredientes/carne/fried.png"
		}
	},
	"farofa": {
		"display_name": "Farofa",
		"container": "res://assets/ingredientes/farofa/container.png",
		"states": {
			"raw": "res://assets/ingredientes/farofa/raw.png"
		}
	},
	"mortadela": {
		"display_name": "Mortadela",
		"container": "res://assets/ingredientes/mortadela/container.png",
		"states": {
			"raw": "res://assets/ingredientes/mortadela/raw.png"
		}
	},
	"queijo": {
		"display_name": "Queijo",
		"container": "res://assets/ingredientes/queijo/container.png",
		"states": {
			"raw": "res://assets/ingredientes/queijo/raw.png"
		}
	},
	"arroz": {
		"display_name": "Arroz",
		"container": "res://assets/ingredientes/arroz/container.png",
		"states": {
			"raw": "res://assets/ingredientes/arroz/raw.png"
		}
	},
	"cuscuz": {
		"display_name": "Cuscuz",
		"container": "res://assets/ingredientes/cuscuz/container.png",
		"states": {
			"raw": "res://assets/ingredientes/cuscuz/raw.png"
		}
	},
	"pao de queijo": {
		"display_name": "Pão de queijo",
		"container": "res://assets/ingredientes/pao de queijo/container.png",
		"states": {
			"raw": "res://assets/ingredientes/pao de queijo/raw.png"
		}
	},
	"presunto": {
		"display_name": "Presunto",
		"container": "res://assets/ingredientes/presunto/container.png",
		"states": {
			"raw": "res://assets/ingredientes/presunto/raw.png"
		}
	},
	"feijao": {
		"display_name": "Feijão",
		"container": "res://assets/ingredientes/feijao/container.png",
		"states": {
			"raw": "res://assets/ingredientes/feijao/raw.png"
		}
	},
	"pimentao": {
		"display_name": "Pimentão",
		"container": "res://assets/ingredientes/pimentao/container.png",
		"states": {
			"raw": "res://assets/ingredientes/pimentao/raw.png"
		}
	},
	"pao": {
		"display_name": "Pão",
		"container": "res://assets/ingredientes/pao/container.png",
		"states": {
			"raw": "res://assets/ingredientes/pao/raw.png"
		}
	},
	"ovo": {
		"display_name": "Ovo",
		"container": "res://assets/ingredientes/ovo/container.png",
		"states": {
			"raw": "res://assets/ingredientes/ovo/raw.png"
		}
	},
	"manteiga": {
		"display_name": "Manteiga",
		"container": "res://assets/ingredientes/manteiga/container.png",
		"states": {
			"raw": "res://assets/ingredientes/manteiga/raw.png"
		}
	},
}


# Retorna o caminho para o sprite correspondente ao estado do ingrediente (ex: raw, cut, etc.)
func get_sprite_path(id: String, state: String) -> String:
	if DATA.has(id):
		var states = DATA[id].get("states", {})
		if state in states:
			return states[state]
	return ""


# Retorna o nome amigável (para exibição) do ingrediente.
func get_display_name(id: String, _state: String = "") -> String:
	if DATA.has(id):
		return DATA[id].get("display_name", id)
	return id


# Retorna o caminho da imagem do container do ingrediente.
func get_container_sprite(id: String) -> String:
	if DATA.has(id):
		return DATA[id].get("container", "")
	return ""


# Verifica se o ingrediente possui um determinado estado (ex: "cut", "fried", etc.)
func has_state(id: String, state: String) -> bool:
	if DATA.has(id):
		return DATA[id].has("states") and DATA[id]["states"].has(state)
	return false
