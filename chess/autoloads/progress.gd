## Long-term progress (autoload "Progress"): what the player discovered and a
## few stats, kept between runs in a JSON save file.
extends Node

signal changed

const DEFAULT_PATH := "user://save.json"

## Tests point this at a throwaway file.
var path := DEFAULT_PATH

## Resource paths of the discovered pieces, gambits and bosses.
var pieces: Array[String] = []
var gambits: Array[String] = []
var bosses: Array[String] = []
var runs_started := 0
var runs_won := 0
var best_stage := 0


func _ready() -> void:
	load_progress()


func is_discovered(resource: Resource) -> bool:
	return resource.resource_path in _list_for(resource)


func discover(resource: Resource) -> void:
	var list := _list_for(resource)
	if resource.resource_path.is_empty() or resource.resource_path in list:
		return
	list.append(resource.resource_path)
	_on_changed()


func discover_all(resources: Array) -> void:
	for resource: Resource in resources:
		discover(resource)


func record_run_started() -> void:
	runs_started += 1
	_on_changed()


func record_run_won() -> void:
	runs_won += 1
	_on_changed()


func record_stage(stage: int) -> void:
	if stage > best_stage:
		best_stage = stage
		_on_changed()


func clear() -> void:
	pieces.clear()
	gambits.clear()
	bosses.clear()
	runs_started = 0
	runs_won = 0
	best_stage = 0
	_on_changed()


func load_progress() -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		push_warning("Ignoring broken save file %s" % path)
		return
	var data: Dictionary = json.data
	
	pieces.assign(data.get("pieces", []))
	gambits.assign(data.get("gambits", []))
	bosses.assign(data.get("bosses", []))
	runs_started = int(data.get("runs_started", 0))
	runs_won = int(data.get("runs_won", 0))
	best_stage = int(data.get("best_stage", 0))


func save_progress() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Can't write save file %s" % path)
		return
	
	file.store_string(JSON.stringify({
		"pieces": pieces,
		"gambits": gambits,
		"bosses": bosses,
		"runs_started": runs_started,
		"runs_won": runs_won,
		"best_stage": best_stage,
	}, "\t"))


func _list_for(resource: Resource) -> Array[String]:
	if resource is UnitStats:
		return pieces
	if resource is GambitData:
		return gambits
	if resource is BossData:
		return bosses
	assert(false, "Can't discover %s" % resource)
	return []


func _on_changed() -> void:
	save_progress()
	changed.emit()
