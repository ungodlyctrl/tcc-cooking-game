extends Control
class_name DragCatchZone

func _can_drop_data(position, data):
	return true  # Aceita qualquer coisa passando

func _drop_data(position, data):
	pass  # Não faz nada, só serve pra evitar o cursor bloqueado
	
