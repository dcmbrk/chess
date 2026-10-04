## All encounters the game can pick from.
class_name EncounterLibrary
extends Resource

@export var encounters: Array[EncounterData] = []


## Picks a random encounter for [param stage]. Falls back to the closest
## easier stage when none matches exactly.
func pick(stage: int, is_boss: bool, rng: RandomNumberGenerator) -> EncounterData:
	for candidate_stage in range(stage, 0, -1):
		var candidates := encounters.filter(func(encounter: EncounterData) -> bool:
			return encounter.stage == candidate_stage and encounter.is_boss == is_boss
		)
		if not candidates.is_empty():
			return candidates[rng.randi_range(0, candidates.size() - 1)]
	
	return null
