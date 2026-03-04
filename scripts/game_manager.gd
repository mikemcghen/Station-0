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
	RunManager.start_run(0, [], [])
	change_state(GameState.RUN)
	get_tree().change_scene_to_file("res://scenes/run/floor.tscn")

func _on_run_started() -> void:
	change_state(GameState.RUN)

func _on_run_ended(_survived: bool) -> void:
	# Body parts are always kept — save before returning to hub
	SaveManager.save()
	call_deferred("go_to_hub")
