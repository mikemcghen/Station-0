extends Area2D

var part: BodyPartData = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and part != null:
		UpgradeManager.acquire_part(part)
		queue_free()
