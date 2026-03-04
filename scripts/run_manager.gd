extends Node

var current_floor: int = 0
var current_room_id: String = ""
var run_active: bool = false

# --- Collected this run (lost on death) ---
var run_items: Array[Resource] = []
var card_packs_found: Array[Resource] = []

# --- Brought into the run (lost on death) ---
var credits_brought_in: int = 0
var buff_items_brought: Array[Resource] = []
var npc_ids_on_run: Array[String] = []

# --- Floor-to-floor carry (not saved, only lives for one scene reload) ---
var player_health_carry: float = -1.0   # -1 = no carry, use default full health

func start_run(brought_credits: int, brought_buffs: Array[Resource], brought_npc_ids: Array[String]) -> void:
	current_floor = 1
	current_room_id = ""
	run_active = true
	player_health_carry = -1.0
	run_items.clear()
	card_packs_found.clear()
	credits_brought_in = brought_credits
	buff_items_brought = brought_buffs.duplicate()
	npc_ids_on_run = brought_npc_ids.duplicate()
	EventBus.run_started.emit()

func end_run(player_survived: bool) -> void:
	run_active = false
	if player_survived:
		_apply_run_rewards()
	else:
		_apply_run_death()
	EventBus.run_ended.emit(player_survived)

func advance_floor() -> void:
	EventBus.floor_cleared.emit(current_floor)
	current_floor += 1

func collect_item(item: Resource) -> void:
	run_items.append(item)
	EventBus.item_collected.emit(item)

func collect_card_pack(pack: Resource) -> void:
	card_packs_found.append(pack)
	EventBus.card_pack_found.emit(pack)

func _apply_run_rewards() -> void:
	# Permanent: card packs go to collection
	for pack in card_packs_found:
		CardCollection.open_pack(pack)
	# Credits brought in are returned plus any earned during the run
	UpgradeManager.hub_credits += credits_brought_in
	# NPCs survive
	for npc_id in npc_ids_on_run:
		NPCManager.return_npc_to_hub(npc_id)

func _apply_run_death() -> void:
	# Everything brought in / found is lost
	run_items.clear()
	card_packs_found.clear()
	credits_brought_in = 0
	buff_items_brought.clear()
	# NPCs on run are lost
	for npc_id in npc_ids_on_run:
		NPCManager.lose_npc(npc_id)
	npc_ids_on_run.clear()
	EventBus.player_died.emit()
