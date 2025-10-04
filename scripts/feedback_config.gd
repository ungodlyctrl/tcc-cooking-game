extends Resource
class_name FeedbackConfig

## Frases iniciais por nota
@export var excelente: Array[String] = ["Está perfeito!", "Maravilhoso!", "Não poderia estar melhor!"]
@export var bom: Array[String] = ["Tá muito bom!", "Gostei bastante!", "Mandou bem!"]
@export var medio: Array[String] = ["Tá ok...", "Aceitável, mas pode melhorar.", "Não tá ruim, mas..."]
@export var ruim: Array[String] = ["Tá ruim...", "Não gostei.", "Isso foi decepcionante."]

## Frase final genérica caso não haja feedbacks específicos
@export var fallback: Array[String] = ["Nada a reclamar.", "Tá tudo certo.", "Sem problemas."]
