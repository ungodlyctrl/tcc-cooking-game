extends Resource
class_name SlotEntry

@export var ingredient_id: String = ""
@export var pos: Vector2 = Vector2.ZERO        # posição (x,y) relativa ao PrepArea (top-left)
@export var size: Vector2 = Vector2(64, 64)    # custom_minimum_size do slot (largura, altura)
@export var name: String = ""                  # opcional, nome do nó (para debug)
