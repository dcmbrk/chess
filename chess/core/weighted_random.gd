class_name WeightedRandom
extends RefCounted


## Picks one of [param items]; an item with weight 2 is twice as likely as one with weight 1.
static func pick(items: Array, weights: Array[int], rng: RandomNumberGenerator) -> Variant:
	assert(items.size() == weights.size(), "Every item needs a weight!")
	
	var total := 0
	for weight in weights:
		total += weight
	assert(total > 0, "At least one weight must be positive!")
	
	var roll := rng.randi_range(1, total)
	for i in items.size():
		roll -= weights[i]
		if roll <= 0:
			return items[i]
	
	return items.back()
