extends Resource
class_name UtensilEntry

# node_name deve ser exatamente o nome do nó filho que está em UtensilsParent
@export var node_name: String = ""
@export var pos: Vector2 = Vector2.ZERO
@export var size: Vector2 = Vector2.ZERO   # se Vector2.ZERO -> não altera tamanho
@export var visible: bool = true
