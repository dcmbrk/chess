extends GutTest

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 7


func test_single_item_is_always_picked() -> void:
	for i in 10:
		assert_eq(WeightedRandom.pick(["a"], [1] as Array[int], rng), "a")


func test_zero_weight_is_never_picked() -> void:
	for i in 200:
		assert_eq(WeightedRandom.pick(["never", "always"], [0, 5] as Array[int], rng), "always")


func test_picks_follow_the_weights() -> void:
	var counts := {"common": 0, "rare": 0}
	for i in 1000:
		counts[WeightedRandom.pick(["common", "rare"], [3, 1] as Array[int], rng)] += 1
	
	# Expected 750 / 250.
	assert_between(counts["common"], 680, 820)
	assert_eq(counts["common"] + counts["rare"], 1000)


func test_same_seed_gives_same_picks() -> void:
	var other := RandomNumberGenerator.new()
	other.seed = 7
	var items := ["a", "b", "c"]
	var weights: Array[int] = [1, 2, 3]
	
	for i in 20:
		assert_eq(WeightedRandom.pick(items, weights, rng), WeightedRandom.pick(items, weights, other))
