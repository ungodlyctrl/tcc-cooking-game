extends Node

## Configuração centralizada de penalidades e pagamentos
const PENALTIES: Dictionary = {
	"missing": 20,
	"wrong_qty": 8,
	"extra_qty": 4,
	"wrong_state": 10,
	"bad_cook": 8,
	"meh_cook": 5,
	"extra": 8,
	"qte_miss": 2,
	"time": 1
}

const PAYMENT_MULTIPLIERS: Dictionary = {
	"Excelente": 1.15,
	"Bom": 1.0,
	"Médio": 0.9,
	"Ruim": 0.6
}

## Tradução de estados → masculino/feminino
const STATE_LABELS: Dictionary = {
	"fried": {"m": "frito", "f": "frita"},
	"cooked": {"m": "cozido", "f": "cozida"},
	"cut": {"m": "cortado", "f": "cortada"},
	"raw": {"m": "cru", "f": "crua"},
	"burnt": {"m": "queimado", "f": "queimada"},
	"meh": {"m": "mais ou menos", "f": "mais ou menos"},
	"perfect": {"m": "no ponto", "f": "no ponto"}
}

const RESULT_LABELS: Dictionary = {
	"burnt": {"m": "queimado", "f": "queimada"},
	"raw": {"m": "cru", "f": "crua"},
	"meh": {"m": "mais ou menos", "f": "mais ou menos"},
	"perfect": {"m": "no ponto", "f": "no ponto"}
}

const DEFAULT_FEEDBACK_OPENINGS: Dictionary = {
	"Excelente": ["Perfeito!", "Maravilhoso!", "Isso ficou ótimo!"],
	"Bom": ["Tá bom!", "Gostei bastante.", "Mandou bem!"],
	"Médio": ["Tá ok...", "Pode melhorar.", "Aceitável."],
	"Ruim": ["Não gostei.", "Isso deixou a desejar.", "Tô decepcionado."]
}

const DEFAULT_FALLBACKS: Array = ["Nada a reclamar.", "Sem problemas."]

## --- Gerador de comentários naturais ---
func _build_comment(grade: String, opening: String, feedbacks: Array[String]) -> String:
	if feedbacks.is_empty():
		return opening + " " + DEFAULT_FALLBACKS.pick_random()

	# Separar categorias
	var burnt: Array[String] = []
	var raw: Array[String] = []
	var extras: Array[String] = []
	var missing: Array[String] = []
	var wrong_state: Array[String] = []
	var others: Array[String] = []

	for f in feedbacks:
		if "queim" in f: burnt.append(f)
		elif "cru" in f: raw.append(f)
		elif "não fazia parte" in f: extras.append(f)
		elif "faltou" in f: missing.append(f)
		elif "não estava" in f: wrong_state.append(f)
		else: others.append(f)

	var phrases: Array[String] = []

	# 🔹 Agrupamentos naturais
	if burnt.size() > 1:
		phrases.append("Alguns ingredientes queimaram")
	elif burnt.size() == 1:
		phrases.append(burnt[0])

	if raw.size() > 1:
		phrases.append("Alguns ingredientes ficaram crus")
	elif raw.size() == 1:
		phrases.append(raw[0])

	# ⚙️ Fix: concatenar arrays sem quebrar tipagem
	for group in [wrong_state, extras, missing, others]:
		for phrase in group:
			phrases.append(phrase)

	# 🔹 Caso de “receita errada”
	if (extras.size() + missing.size()) >= 2:
		var cfg: FeedbackConfig = Managers.feedback_config if Managers and Managers.feedback_config != null else null
		var confused_lines: Array[String] = []
		if cfg and cfg.recipe_confused.size() > 0:
			confused_lines = cfg.recipe_confused
		else:
			confused_lines = [
				"Não foi isso que eu pedi.",
				"Acho que você confundiu o pedido.",
				"Isso não é o que eu pedi.",
				"Você fez outra coisa."
			]
		return confused_lines.pick_random()

	# 🔹 Chance de comentário curto (sem detalhes)
	if randf() < 0.25:
		return opening

	# 🔹 Limitar número de críticas
	if phrases.size() > 2:
		phrases = phrases.slice(0, 2)
		phrases.append("e outras coisinhas")

	# 🔹 Suavizar se nota for alta
	if grade in ["Excelente", "Bom"]:
		for i in range(phrases.size()):
			phrases[i] = "Só cuidado, " + phrases[i]

	return opening + " " + ". ".join(phrases) + "."


## --- Avaliação do prato ---
func evaluate_plate(
	recipe: RecipeResource,
	delivered_ingredients: Array,
	order_start_minutes: int,
	current_time_minutes: int,
	qte_results: Dictionary
) -> Dictionary:
	var score: int = 100
	var breakdown: Dictionary = {
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
	var expected: Array = recipe.ingredient_requirements.duplicate() if recipe else []
	var expected_ids: Array[String] = []
	for req in expected:
		if req and req.ingredient_id != "": expected_ids.append(req.ingredient_id)

	# Agrupar entregues
	var delivered: Dictionary = {}
	for item in delivered_ingredients:
		if typeof(item) != TYPE_DICTIONARY: continue
		var id: String = item.get("id", "")
		if id == "": continue
		if not delivered.has(id):
			delivered[id] = {"count": 0, "states": [], "results": []}
		delivered[id]["count"] += 1
		delivered[id]["states"].append(item.get("state", ""))
		delivered[id]["results"].append(item.get("result", ""))

	# Verificar
	for req in expected:
		if req == null: continue
		var id: String = req.ingredient_id
		var needed: int = int(req.quantity)
		var delivered_info: Variant = delivered.get(id, null)

		var ing_data: IngredientData = Managers.ingredient_database.get_ingredient(id) if Managers and Managers.ingredient_database else null
		var ing_name: String = ing_data.display_name if ing_data and ing_data.display_name != "" else id.capitalize()
		var gender: String = "m"
		if ing_data and ing_data.has_method("get"):
			var raw_gender: Variant = ing_data.get("gender")
			if typeof(raw_gender) == TYPE_STRING and raw_gender != "": gender = raw_gender

		if delivered_info == null:
			if not req.optional:
				breakdown["missing"] += 1
				score -= PENALTIES["missing"]
				feedbacks.append("Faltou %s" % ing_name)
			continue

		var used_qty: int = int(delivered_info["count"])
		if used_qty < needed:
			var miss: int = needed - used_qty
			score -= PENALTIES["wrong_qty"] * miss
			breakdown["wrong_qty"] += miss
			feedbacks.append("%s a menos" % ing_name)
		elif used_qty > needed:
			var extra_q: int = used_qty - needed
			score -= PENALTIES["extra_qty"] * extra_q
			breakdown["extra_qty"] += extra_q
			feedbacks.append("%s a mais" % ing_name)

		for state in delivered_info["states"]:
			if state != req.state:
				breakdown["wrong_state"] += 1
				score -= PENALTIES["wrong_state"]
				var readable_state: String = req.state
				if STATE_LABELS.has(req.state):
					var lbls: Dictionary = STATE_LABELS[req.state]
					if lbls.has(gender): readable_state = lbls[gender]
				feedbacks.append("%s não estava %s" % [ing_name, readable_state])

		for result in delivered_info["results"]:
			var readable_result: String = result
			if RESULT_LABELS.has(result):
				var rlbls: Dictionary = RESULT_LABELS[result]
				if rlbls.has(gender): readable_result = rlbls[gender]

			if result in ["burnt", "❌ Queimado!", "🔥 Queimado"]:
				breakdown["bad_cook"] += 1
				score -= PENALTIES["bad_cook"]
				feedbacks.append("%s ficou %s" % [ing_name, readable_result])
			elif result in ["raw", "🧊 Cru"]:
				breakdown["bad_cook"] += 1
				score -= PENALTIES["bad_cook"]
				feedbacks.append("%s estava %s" % [ing_name, readable_result])
			elif result in ["meh", "😐 Mais ou menos"]:
				breakdown["meh_cook"] += 1
				score -= PENALTIES["meh_cook"]
				feedbacks.append("%s ficou %s" % [ing_name, readable_result])

	# Ingredientes extras
	for id_key in delivered.keys():
		if not expected_ids.has(id_key):
			var extra_data: IngredientData = Managers.ingredient_database.get_ingredient(id_key) if Managers and Managers.ingredient_database else null
			var extra_name: String = extra_data.display_name if extra_data and extra_data.display_name != "" else id_key.capitalize()
			breakdown["extra"] += 1
			score -= PENALTIES["extra"]
			feedbacks.append("%s não fazia parte da receita" % extra_name)

	# QTE
	for ing_id in qte_results.keys():
		var hits: int = int(qte_results[ing_id])
		var penalty: int = max(0, 5 - hits) * PENALTIES["qte_miss"]
		breakdown["qte_score"] += hits
		score -= penalty
		if hits < 3:
			var q_data: IngredientData = Managers.ingredient_database.get_ingredient(ing_id) if Managers and Managers.ingredient_database else null
			var q_name: String = q_data.display_name if q_data and q_data.display_name != "" else ing_id.capitalize()
			feedbacks.append("%s foi mal cortado" % q_name)

	# Tempo
	var elapsed_minutes: int = int(current_time_minutes - order_start_minutes)
	var time_penalty: int = int(elapsed_minutes / 15) * PENALTIES["time"]
	score -= time_penalty
	breakdown["time_penalty"] = time_penalty
	if time_penalty > 12:
		feedbacks.append("demorou um pouco para entregar")

	score = clamp(score, 0, 100)

	# Nota
	var grade: String = "Ruim"
	if score >= 90: grade = "Excelente"
	elif score >= 75: grade = "Bom"
	elif score >= 50: grade = "Médio"

	# Frase inicial
	var opening: String = ""
	var cfg: FeedbackConfig = Managers.feedback_config if Managers and Managers.feedback_config != null else null
	if cfg != null:
		match grade:
			"Excelente": if cfg.excelente.size() > 0: opening = cfg.excelente.pick_random()
			"Bom": if cfg.bom.size() > 0: opening = cfg.bom.pick_random()
			"Médio": if cfg.medio.size() > 0: opening = cfg.medio.pick_random()
			"Ruim": if cfg.ruim.size() > 0: opening = cfg.ruim.pick_random()
		if opening == "": opening = DEFAULT_FEEDBACK_OPENINGS[grade].pick_random()
	else:
		opening = DEFAULT_FEEDBACK_OPENINGS[grade].pick_random()

	# Comentário final
	var comment: String = _build_comment(grade, opening, feedbacks)

	# Pagamento
	var base_price: int = recipe.base_price if recipe else 0
	var final_payment: int = int(base_price * PAYMENT_MULTIPLIERS.get(grade, 1.0))

	return {
		"score": score,
		"grade": grade,
		"comment": comment,
		"breakdown": breakdown,
		"payment": final_payment,
		"feedbacks": feedbacks
	}
