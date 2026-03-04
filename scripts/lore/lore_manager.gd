extends Node

# All lore IDs the player has discovered — never lost on death
var discovered: Array[String] = []

func discover(lore_id: String) -> void:
	if lore_id not in discovered:
		discovered.append(lore_id)
		EventBus.lore_discovered.emit(lore_id)

func has_discovered(lore_id: String) -> bool:
	return lore_id in discovered

func get_save_data() -> Array:
	return discovered.duplicate()

func load_save_data(data: Array) -> void:
	discovered.clear()
	for entry in data:
		discovered.append(str(entry))
