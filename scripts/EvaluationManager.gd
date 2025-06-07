extends Node

func evaluate_plate(
	recipe: RecipeResource,
	delivered_ingredients: Array[Dictionary],
	order_start_minutes: int,
	current_time_minutes: int,
	qte_results: Dictionary
) -> Dictionary:
	var score := 100
	var breakdown := {
		"missing": 0,
		"wrong_state": 0,
		"extra": 0,
		"bad_cook": 0,
		"qte_score": 0,
		"time_penalty": 0
	}

	var expected := recipe.ingredient_requirements.duplicate()
	var expected_ids := expected.map(func(r): return r.ingredient_id)

	# Agrupa ingredientes entregues por ID
	var delivered := {}
	for item in delivered_ingredients:
		var id : String = item.get("id", "")
		if not delivered.has(id):
			delivered[id] = { "count": 0, "states": [], "results": [] }
		delivered[id]["count"] += 1
		delivered[id]["states"].append(item.get("state", ""))
		delivered[id]["results"].append(item.get("result", ""))

	# Verifica correspondência com os requisitos da receita
	for req in expected:
		var id : String = req.ingredient_id
		var needed : int = req.quantity
		var delivered_info = delivered.get(id, null)

		if delivered_info == null:
			if not req.optional:
				breakdown["missing"] += 1
				score -= 20
			continue

		var used_qty: int = delivered_info["count"]
		if used_qty < needed:
			score -= 8 * (needed - used_qty)
		elif used_qty > needed:
			score -= 4 * (used_qty - needed)

		# Estado final do ingrediente
		for state in delivered_info["states"]:
			if state != req.state:
				breakdown["wrong_state"] += 1
				score -= 10

		# Resultado do minigame de cozimento/fritura
		for result in delivered_info["results"]:
			match result:
				"burnt", "cru", "❌ Queimado!", "🧊 Cru":
					breakdown["bad_cook"] += 1
					score -= 8
				"😐 Mais ou menos":
					score -= 5

	# Ingredientes que não fazem parte da receita
	for id in delivered.keys():
		if not expected_ids.has(id):
			breakdown["extra"] += 1
			score -= 6

	# Avaliação dos QTEs (corte)
	for ing_id in qte_results.keys():
		var hits: int = qte_results[ing_id]
		var penalty: int  = max(0, 5 - hits) * 2
		breakdown["qte_score"] += hits
		score -= penalty

	# Penalidade por tempo de preparo (1 ponto a cada 15 minutos do jogo)
	var elapsed_minutes : int = current_time_minutes - order_start_minutes
	@warning_ignore("integer_division")
	var time_penalty : int = int(elapsed_minutes / 15)
	score -= time_penalty
	breakdown["time_penalty"] = time_penalty

	# Clamp final
	score = clamp(score, 0, 100)

	# Geração do feedback textual
	var grade : String = ""
	var comment : String = ""

	if score >= 90:
		grade = "Excelente"
		comment = "Perfeito!"
	elif score >= 75:
		grade = "Bom"
		comment = "Gostei bastante!"
	elif score >= 50:
		grade = "Médio"
		comment = "Tá ok... mas podia melhorar."
	else:
		grade = "Ruim"
		comment = "Tô decepcionado..."
		

	

	return {
		"score": score,
		"grade": grade,
		"comment": comment,
		"breakdown": breakdown
	}
