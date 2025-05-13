extends Node

var data = {
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
		"container": "res://assets/ingredientes/farofa/container.png"
	},
	"mortadela": {
		"display_name": "Mortadela",
		"container": "res://assets/ingredientes/mortadela/container.png"
	},
	"queijo": {
		"display_name": "Queijo",
		"container": "res://assets/ingredientes/queijo/container.png"
	},
	"arroz": {
		"display_name": "Arroz",
		"container": "res://assets/ingredientes/arroz/container.png"
	},
	"cuscuz": {
		"display_name": "Cuscuz",
		"container": "res://assets/ingredientes/cuscuz/container.png"
	},
	"pao de queijo": {
		"display_name": "Pao de queijo",
		"container": "res://assets/ingredientes/pao de queijo/container.png"
	},
	"presunto": {
		"display_name": "Presunto",
		"container": "res://assets/ingredientes/presunto/container.png"
	},
	"salsicha": {
		"display_name": "Salsicha",
		"container": "res://assets/ingredientes/salsicha/container.png"
	},
	
}

func get_sprite_path(id: String, state: String) -> String:
	if data.has(id) and data[id].has("states") and data[id]["states"].has(state):
		return data[id]["states"][state]
	return ""

func get_display_name(id: String, state: String = "") -> String:
	if data.has(id):
		return data[id].get("display_name", id)
	return id

func get_container_sprite(id: String) -> String:
	if data.has(id) and data[id].has("container"):
		return data[id]["container"]
	return ""
