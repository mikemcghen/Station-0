class_name RoomData

enum RoomType { START, COMBAT, ITEM, SHOP, BOSS }

var type:        RoomType   = RoomType.COMBAT
var grid_pos:    Vector2i   = Vector2i.ZERO
var connections: Dictionary = {}   # "up"/"down"/"left"/"right" -> Vector2i
var visited:     bool       = false
var cleared:     bool       = false
