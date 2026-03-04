extends Node

# card_id -> count owned
var collection: Dictionary = {}

# Array of { name: String, card_ids: Array[String] }
var decks: Array[Dictionary] = []

func add_card(card_id: String, count: int = 1) -> void:
	collection[card_id] = collection.get(card_id, 0) + count

func get_card_count(card_id: String) -> int:
	return collection.get(card_id, 0)

func open_pack(pack: Resource) -> void:
	# Pack resource defines its card_ids array
	if pack == null or not pack.get("card_ids"):
		return
	for card_id in pack.card_ids:
		add_card(card_id)

func create_deck(deck_name: String) -> void:
	decks.append({ "name": deck_name, "card_ids": [] })

func get_save_data() -> Dictionary:
	return {
		"collection": collection.duplicate(),
		"decks": decks.duplicate(true),
	}

func load_save_data(data: Dictionary) -> void:
	collection = data.get("collection", {})
	decks = data.get("decks", [])
