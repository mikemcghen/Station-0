extends Node

# ---------------------------------------------------------------------------
# AudioManager — singleton for playing sound effects
# Uses a pool of AudioStreamPlayers to allow overlapping sounds
# ---------------------------------------------------------------------------

const POOL_SIZE := 8

# Preloaded sound effects
var _sounds: Dictionary = {
	"enemy_hit": preload("res://assets/audio/sfx/enemy_hit.wav"),
	"enemy_death": preload("res://assets/audio/sfx/enemy_death.wav"),
	"enemy_shoot": preload("res://assets/audio/sfx/enemy_shoot.wav"),
	"player_hit": preload("res://assets/audio/sfx/player_hit.wav"),
	"player_shoot": preload("res://assets/audio/sfx/player_shoot.wav"),
	"explosion": preload("res://assets/audio/sfx/explosion.wav"),
	"pickup_scrap": preload("res://assets/audio/sfx/pickup_scrap.wav"),
	"item_pickup": preload("res://assets/audio/sfx/item_pickup.wav"),
	"ui_click": preload("res://assets/audio/sfx/ui_click.wav"),
	"ui_select": preload("res://assets/audio/sfx/ui_select.wav"),
	"door_close": preload("res://assets/audio/sfx/door_close.wav"),
	"room_clear": preload("res://assets/audio/sfx/room_clear.wav"),
	"teleport": preload("res://assets/audio/sfx/teleport.wav"),
}

var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_pool.append(player)

func play(sound_name: String) -> void:
	if not _sounds.has(sound_name):
		push_warning("AudioManager: Unknown sound '%s'" % sound_name)
		return

	var player := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE

	player.stream = _sounds[sound_name]
	player.play()
