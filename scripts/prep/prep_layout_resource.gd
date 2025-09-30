extends Resource
class_name PrepLayoutResource

@export var min_day: int = 1                      # a partir de qual dia esse preset torna-se válido
@export var slots: Array[SlotEntry] = []        # array de SlotEntry resources (criado no editor)
@export var utensils: Array[UtensilEntry] = []                 # array de UtensilEntry resources
@export var utensils_offset: Vector2 = Vector2(0,0) # offset extra para a coluna de utensílios (opcional)
@export var background_min_height: int = 0     # força altura mínima do fundo (0 = usar conteúdo)
