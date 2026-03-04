extends Node

const SAVE_PATH := "user://save.cfg"

func save() -> void:
	var data := ConfigFile.new()
	data.set_value("upgrades", "parts", UpgradeManager.get_save_data())
	data.set_value("upgrades", "hub_credits", UpgradeManager.hub_credits)
	data.set_value("cards", "collection", CardCollection.get_save_data())
	data.set_value("npcs", "registry", NPCManager.get_save_data())
	data.set_value("lore", "discovered", LoreManager.get_save_data())
	data.save(SAVE_PATH)

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data := ConfigFile.new()
	data.load(SAVE_PATH)
	UpgradeManager.load_save_data(data.get_value("upgrades", "parts", {}))
	UpgradeManager.hub_credits = data.get_value("upgrades", "hub_credits", 0)
	CardCollection.load_save_data(data.get_value("cards", "collection", {}))
	NPCManager.load_save_data(data.get_value("npcs", "registry", {}))
	LoreManager.load_save_data(data.get_value("lore", "discovered", []))

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
