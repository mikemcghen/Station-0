extends Node

enum NPCState {
	UNDISCOVERED,
	IN_HUB,
	ON_RUN,
	LOST,
}

# npc_id -> { state: NPCState, resource_path: String }
var _registry: Dictionary = {}

func register_npc(npc_id: String, resource_path: String) -> void:
	if npc_id not in _registry:
		_registry[npc_id] = {
			"state": NPCState.UNDISCOVERED,
			"resource_path": resource_path,
		}

func discover_npc(npc_id: String) -> void:
	if npc_id not in _registry:
		return
	_registry[npc_id]["state"] = NPCState.IN_HUB
	var npc := _load_npc(npc_id)
	if npc:
		EventBus.npc_saved.emit(npc)

func send_on_run(npc_id: String) -> void:
	if npc_id in _registry:
		_registry[npc_id]["state"] = NPCState.ON_RUN

func return_npc_to_hub(npc_id: String) -> void:
	if npc_id in _registry:
		_registry[npc_id]["state"] = NPCState.IN_HUB

func lose_npc(npc_id: String) -> void:
	if npc_id not in _registry:
		return
	_registry[npc_id]["state"] = NPCState.LOST
	var npc := _load_npc(npc_id)
	if npc:
		EventBus.npc_lost.emit(npc)

func get_hub_npc_ids() -> Array[String]:
	var result: Array[String] = []
	for npc_id in _registry:
		if _registry[npc_id]["state"] == NPCState.IN_HUB:
			result.append(npc_id)
	return result

func get_state(npc_id: String) -> NPCState:
	return _registry.get(npc_id, {}).get("state", NPCState.UNDISCOVERED)

func get_save_data() -> Dictionary:
	var data := {}
	for npc_id in _registry:
		data[npc_id] = {
			"state": _registry[npc_id]["state"],
			"resource_path": _registry[npc_id]["resource_path"],
		}
	return data

func load_save_data(data: Dictionary) -> void:
	_registry.clear()
	for npc_id in data:
		_registry[npc_id] = data[npc_id].duplicate()

func _load_npc(npc_id: String) -> Resource:
	var path: String = _registry[npc_id].get("resource_path", "")
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null
