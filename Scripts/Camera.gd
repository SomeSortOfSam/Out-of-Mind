class_name Camera
extends Veiwer

@onready var light : PointLight2D = $PointLight2D
@onready var sound : AudioStreamPlayer2D = $AudioStreamPlayer2D

var cell : Vector2i
var on := false

signal turned_on(seen_tiles)

func turn_on():
	light.enabled = true
	sound.play()
	on = true
	var seen_tiles := PackedVector2Array()
	for tile in map.get_used_cells(1):
		if get_is_visible(tile):
			@warning_ignore(return_value_discarded)
			seen_tiles.append(tile)
	@warning_ignore(return_value_discarded)
	emit_signal("turned_on",seen_tiles)

func _on_player_moved(new_cell : Vector2i):
	if new_cell in map.get_surrounding_tiles(cell) && !on:
		turn_on()
