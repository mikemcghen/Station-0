extends Node

enum GameState {
	HUB,
	RUN,
	CARD_GAME,
	CUTSCENE,
	PAUSED,
}

var current_state: GameState = GameState.HUB
var _previous_state: GameState = GameState.HUB

const RunEndScreenScene = preload("res://scripts/ui/run_end_screen.gd")

var _run_end_screen: CanvasLayer = null

func _ready() -> void:
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	call_deferred("_load_game")

func _load_game() -> void:
	SaveManager.load_save()

func change_state(new_state: GameState) -> void:
	_previous_state = current_state
	current_state = new_state

func pause() -> void:
	if current_state != GameState.PAUSED:
		change_state(GameState.PAUSED)
		get_tree().paused = true

func unpause() -> void:
	if current_state == GameState.PAUSED:
		change_state(_previous_state)
		get_tree().paused = false

func go_to_hub() -> void:
	change_state(GameState.HUB)
	get_tree().change_scene_to_file("res://scenes/hub/hub.tscn")

func start_run() -> void:
	# Bring everything in the wallet into the run — it's on the player, so it's at risk
	var brought := UpgradeManager.wallet_credits
	UpgradeManager.wallet_credits = 0
	RunManager.start_run(brought, [], [])
	change_state(GameState.RUN)
	get_tree().change_scene_to_file("res://scenes/run/floor.tscn")

func _on_run_started() -> void:
	change_state(GameState.RUN)

func _on_run_ended(reached_hub: bool) -> void:
	# Save immediately — body parts and bank are always kept
	SaveManager.save()
	# Show end screen; it calls go_to_hub() when ready
	_run_end_screen = RunEndScreenScene.new()
	get_tree().root.add_child(_run_end_screen)
	_run_end_screen.show_result(reached_hub)
