class_name Player
extends Node2D

const WALL_TILE_IDS := [0,1]
const WIN_TILE_ID := 3

@onready var map : TileMap = $".."
var current_cell : Vector2i
var _is_moving : bool

signal won

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var input : Vector2i = Vector2i(Input.get_axis("ui_left","ui_right"), Input.get_axis("ui_up","ui_down"))
	if !_is_moving && input != Vector2i.ZERO && map.get_cell_source_id(0,current_cell + input) not in WALL_TILE_IDS:
		print(input,current_cell)
		current_cell += input
		translate(input * map.tile_set.tile_size)
		if map.get_cell_source_id(0,current_cell) == WIN_TILE_ID:
			emit_signal("won")
