class_name Player
extends Node2D

const WIN_TILE_ID := 3

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
		raycast.target_position = to_local(cell * map.tile_set.tile_size * 1.0 + map.tile_set.tile_size/2.0)
		await get_tree().physics_frame
		var collision_cell := map.local_to_map(raycast.get_collision_point())
		if collision_cell == cell && in_sight_set.append(cell):
			map.get_cell_tile_data(1,cell).modulate = Color.DARK_GREEN
		elif (raycast.is_colliding() || collision_cell != cell) && Vector2(cell) in in_sight_set:
			map.set_cell(1,cell,-1,Vector2i.ONE * -1,0)
			if raycast.is_colliding():
				(raycast.get_collider() as Node2D).get_node("..").queue_free()