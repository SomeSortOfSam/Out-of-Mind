class_name Camera
extends Veiwer

@onready var light : PointLight2D = $PointLight2D
@onready var sound : AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var sprite: Sprite2D = $Sprite2D

var cell : Vector2i
var on := false

signal turned_on(seen_tiles)

func turn_on():
	light.enabled = true
	sprite.frame = 1
	sound.play()
	var seen_tiles := PackedVector2Array()
	for cell in map.get_used_cells(1):
		if get_is_visible(cell):
			seen_tiles.append(cell)
	emit_signal("turned_on",seen_tiles)

func _on_player_moved(new_cell : Vector2i):
	if new_cell in map.get_surrounding_tiles(cell) && !on:
		turn_on()
