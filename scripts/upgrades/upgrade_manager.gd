extends Node

const SLOTS: Array[String] = ["head", "torso", "left_arm", "right_arm", "legs"]

var hub_credits: int = 0

# slot -> BodyPart resource path (empty string = default/base part)
var equipped_parts: Dictionary = {
	"head": "",
	"torso": "",
	"left_arm": "",
	"right_arm": "",
	"legs": "",
}

# All permanently acquired part resource paths
var acquired_part_paths: Array[String] = []

func equip_part(part: Resource) -> void:
	var slot: String = part.slot
	if slot not in SLOTS:
		push_error("UpgradeManager: invalid slot '%s'" % slot)
		return
	equipped_parts[slot] = part.resource_path
	EventBus.body_part_equipped.emit(part, slot)

func acquire_part(part: Resource) -> void:
	if part.resource_path not in acquired_part_paths:
		acquired_part_paths.append(part.resource_path)
	EventBus.body_part_found.emit(part)

func get_equipped_part(slot: String) -> Resource:
	var path: String = equipped_parts.get(slot, "")
	if path != "":
		return load(path)
	return null

func get_stat_modifier(stat: String) -> float:
	var total := 0.0
	for slot in SLOTS:
		var part := get_equipped_part(slot)
		if part == null:
			continue
		match stat:
			"speed":      total += part.mod_speed
			"max_health": total += part.mod_max_health
			"damage":     total += part.mod_damage
			"fire_rate":  total += part.mod_fire_rate
			"range":      total += part.mod_range
			"proj_speed": total += part.mod_proj_speed
	return total

func get_save_data() -> Dictionary:
	return {
		"equipped": equipped_parts.duplicate(),
		"acquired": acquired_part_paths.duplicate(),
	}

func load_save_data(data: Dictionary) -> void:
	var saved_equipped: Dictionary = data.get("equipped", {})
	for slot in SLOTS:
		equipped_parts[slot] = saved_equipped.get(slot, "")
	acquired_part_paths = data.get("acquired", [])
