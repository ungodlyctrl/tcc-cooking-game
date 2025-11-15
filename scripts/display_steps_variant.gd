extends Resource
class_name DisplayStepsVariant

## Ingredientes que devem estar faltando para esta variante ser ativada
@export var missing: Array[String] = []

## Passos personalizados quando esses ingredientes estiverem faltando
@export var steps: Array[String] = []
