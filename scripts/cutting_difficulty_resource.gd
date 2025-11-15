extends Resource
class_name CuttingDifficultyResource

# metadata
@export var name: String = "default"
@export var min_day: int = 1   # a partir de qual dia esse preset é válido

# core params
@export var pointer_speed: float = 80.0        # pixels por segundo
@export var attempts: int = 3                   # tentativas (cliques)
@export var pointer_bounce: bool = true         # vai até o fim, volta e termina
@export var pointer_auto_end_on_return: bool = true  # encerra quando voltar ao começo

# hitzone config (normalizado 0..1 - posição X relativa à barra, size em 0..1 da largura)
@export var hitzone_count: int = 3
@export var hitzone_positions: Array[float] = [0.2, 0.45, 0.7]
@export var hitzone_sizes: Array[float] = [0.12, 0.12, 0.12]

# visual / timing
@export var hitzone_base_modulate: Color = Color(0.803, 0.820, 0.835, 0.45)  # #cdd1d5 semitransparente
@export var hitzone_hit_modulate: Color = Color(0.49, 0.878, 0.506, 0.55)    # tom de verde ao acertar
@export var fail_delay: float = 0.25
