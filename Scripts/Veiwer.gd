class_name Veiwer
extends Node2D

const WIN_TILE_ID := 3
const GLASS_TILE_ID := 1
const OCCLUDER_EXCEPTIONS := [GLASS_TILE_ID,WIN_TILE_ID]

@onready var raycast : RayCast2D = $RayCast2D

var map : TileMap

func get_is_visible(cell : Vector2i) -> bool:
	for target_position in [to_local(cell * map.tile_set.tile_size + Vector2i.ONE * 4),
	to_local(cell * map.tile_set.tile_size + map.tile_set.tile_size - Vector2i.ONE * 4),
	to_local(cell * map.tile_set.tile_size + map.tile_set.tile_size * Vector2i.RIGHT + Vector2i(-1,1) * 4),
	to_local(cell * map.tile_set.tile_size + map.tile_set.tile_size * Vector2i.DOWN + Vector2i(-1,1) * 4)]:
		raycast.target_position = target_position
		raycast.force_raycast_update()
		if map.get_cell_source_id(1,cell) in OCCLUDER_EXCEPTIONS:
			if !raycast.is_colliding():
				return true
		elif raycast.is_colliding():
			if raycast.get_collider().name == str(cell):
				return true
	return false
