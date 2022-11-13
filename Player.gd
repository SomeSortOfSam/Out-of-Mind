class_name Player
extends Node2D

const WIN_TILE_ID := 3
const GLASS_TILE_ID := 1

@onready var map : TileMap = $".."
@onready var raycast : RayCast2D = $RayCast2D

var current_cell : Vector2i
var tween : Tween
var in_sight_set : PackedVector2Array

signal won

func _ready():
	recaculate_line_of_sight()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if _handle_inputs():
		recaculate_line_of_sight()

func _handle_inputs() -> bool:
	@warning_ignore(narrowing_conversion)
	var input : Vector2i = Vector2i(Input.get_axis("ui_left","ui_right"), Input.get_axis("ui_up","ui_down"))
	if (!tween || !tween.is_running()) && input != Vector2i.ZERO && map.get_cell_source_id(1,current_cell + input) == -1:
		current_cell += input
		tween = create_tween()
		var _tween = tween.tween_property(self,"position",position + input * map.tile_set.tile_size * 1.0,.2)
		if map.get_cell_source_id(0,current_cell) == WIN_TILE_ID:
			var _signal = emit_signal("won")
		return true
	return false

func recaculate_line_of_sight():
	for cell in map.get_used_cells(1):
		if get_is_visible(cell):
			in_sight_set.append(cell)
			if map.get_cell_source_id(1,cell) != GLASS_TILE_ID:
				map.get_cell_tile_data(1,cell).modulate = map.on_color
		elif Vector2(cell) in in_sight_set:
			destory_cell(cell)
		await get_tree().physics_frame

func get_is_visible(cell : Vector2i) -> bool:
	for target_position in [to_local(cell * map.tile_set.tile_size + Vector2i.ONE * 4),
	to_local(cell * map.tile_set.tile_size + map.tile_set.tile_size - Vector2i.ONE * 4),
	to_local(cell * map.tile_set.tile_size + map.tile_set.tile_size * Vector2i.RIGHT + Vector2i(-1,1) * 4),
	to_local(cell * map.tile_set.tile_size + map.tile_set.tile_size * Vector2i.DOWN + Vector2i(-1,1) * 4)]:
		raycast.target_position = target_position
		raycast.force_raycast_update()
		if map.get_cell_source_id(1,cell) == GLASS_TILE_ID:
			if !raycast.is_colliding():
				return true
		elif raycast.is_colliding():
			if raycast.get_collider().name == str(cell):
				return true
	return false

func destory_cell(cell : Vector2i):
	map.erase_cell(1,cell)
	var node = map.get_node(str(cell))
	if node:
		node.queue_free()
	map.set_cells_terrain_connect(2,[cell],0,2)
	map.force_update(2)
