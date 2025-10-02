extends Node

## Configuração centralizada de penalidades e pagamentos
const PENALTIES := {
	"missing": 20,       # ingrediente obrigatório faltando
	"wrong_qty": 8,      # quantidade insuficiente
	"extra_qty": 4,      # quantidade extra
	"wrong_state": 10,   # estado diferente do esperado
	"bad_cook": 8,       # queimado / cru
	"meh_cook": 5,       # “mais ou menos”
	"extra": 6,          # ingrediente que não faz parte da receita
	"qte_miss": 2,       # por erro no corte
	"time": 1            # por 15 minutos
}

const PAYMENT_MULTIPLIERS := {
	"Excelente": 1.15,
	"Bom": 1.0,
	"Médio": 0.9,
	"Ruim": 0.6
}


## Avalia um prato entregue
func evaluate_plate(
	recipe: RecipeResource,
	delivered_ingredients: Array[Dictionary],
	order_start_minutes: int,
	current_time_minutes: int,
	qte_results: Dictionary
) -> Dictionary:
	var score: int = 100
	var breakdown := {
		"missing": 0,
		"wrong_qty": 0,
		"extra_qty": 0,
		"wrong_state": 0,
		"bad_cook": 0,
		"meh_cook": 0,
		"extra": 0,
		"qte_score": 0,
		"time_penalty": 0
	}
	var feedbacks: Array[String] = []

	# Ingredientes esperados
	var expected := recipe.ingredient_requirements.duplicate()
	var expected_ids := expected.map(func(r): return r.ingredient_id)

	# Agrupa entregues
	var delivered := {}
	for item in delivered_ingredients:
		var id: String = item.get("id", "")
		if not delivered.has(id):
			delivered[id] = { "count": 0, "states": [], "results": [] }
		delivered[id]["count"] += 1
		delivered[id]["states"].append(item.get("state", ""))
		delivered[id]["results"].append(item.get("result", ""))

	# Verifica requisitos
	for req in expected:
		var id: String = req.ingredient_id
		var needed: int = req.quantity
		var delivered_info = delivered.get(id, null)

		if delivered_info == null:
			if not req.optional:
				breakdown["missing"] += 1
				score -= PENALTIES["missing"]
				feedbacks.append("Faltou %s" % id.capitalize())
			continue

		# Quantidade
		var used_qty: int = delivered_info["count"]
		if used_qty < needed:
			var miss := needed - used_qty
			score -= PENALTIES["wrong_qty"] * miss
			breakdown["wrong_qty"] += miss
			feedbacks.append("%s a menos" % id.capitalize())
		elif used_qty > needed:
			var extra := used_qty - needed
			score -= PENALTIES["extra_qty"] * extra
			breakdown["extra_qty"] += extra
			feedbacks.append("%s a mais" % id.capitalize())

		# Estado e resultado
		for state in delivered_info["states"]:
			if state != req.state:
				breakdown["wrong_state"] += 1
				score -= PENALTIES["wrong_state"]
				feedbacks.append("%s não estava %s" % [id.capitalize(), req.state])

		for result in delivered_info["results"]:
			match result:
				"burnt", "❌ Queimado!", "🔥 Queimado":
					breakdown["bad_cook"] += 1
					score -= PENALTIES["bad_cook"]
					feedbacks.append("%s queimou" % id.capitalize())
				"raw", "🧊 Cru":
					breakdown["bad_cook"] += 1
					score -= PENALTIES["bad_cook"]
					feedbacks.append("%s estava cru" % id.capitalize())
				"meh", "😐 Mais ou menos":
					breakdown["meh_cook"] += 1
					score -= PENALTIES["meh_cook"]
					feedbacks.append("%s ficou mais ou menos" % id.capitalize())

	# Ingredientes extras
	for id in delivered.keys():
		if not expected_ids.has(id):
			breakdown["extra"] += 1
			score -= PENALTIES["extra"]
			feedbacks.append("%s não fazia parte da receita" % id.capitalize())

	# QTE (corte)
	for ing_id in qte_results.keys():
		var hits: int = qte_results[ing_id]
		var penalty: int = max(0, 5 - hits) * PENALTIES["qte_miss"]
		breakdown["qte_score"] += hits
		score -= penalty
		if hits < 3:
			feedbacks.append("%s foi mal cortado" % ing_id.capitalize())

	# Tempo
	var elapsed_minutes: int = current_time_minutes - order_start_minutes
	@warning_ignore("integer_division")
	var time_penalty: int = int(elapsed_minutes / 15) * PENALTIES["time"]
	score -= time_penalty
	breakdown["time_penalty"] = time_penalty
	if time_penalty > 12:
		feedbacks.append("Demorou um pouco para entregar")

	# Clamp final
	score = clamp(score, 0, 100)

	# Nota
	var grade: String
	if score >= 90:
		grade = "Excelente"
	elif score >= 75:
		grade = "Bom"
	elif score >= 50:
		grade = "Médio"
	else:
		grade = "Ruim"

	# Comentário final
	var comment: String = ""
	if feedbacks.is_empty():
		comment = "Perfeito!"
	else:
		comment = ". ".join(feedbacks) + "."

	# Pagamento calculado aqui
	var base_price: int = recipe.base_price
	var final_payment: int = int(base_price * PAYMENT_MULTIPLIERS[grade])

	return {
		"score": score,
		"grade": grade,
		"comment": comment,
		"breakdown": breakdown,
		"payment": final_payment
	}
