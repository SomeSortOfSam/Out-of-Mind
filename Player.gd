class_name Player
extends Node2D

const WIN_TILE_ID := 3
const GLASS_TILE_ID := 1
const MAX_VOID := 5

@onready var map : TileMap = $".."
@onready var raycast : RayCast2D = $RayCast2D

var current_cell : Vector2i
var tween : Tween
var previous_direction : Vector2i
var in_sight_set : PackedVector2Array
var void_count := 0.0

signal won
signal requesting_restart

func _ready():
	recaculate_line_of_sight()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (!tween || !tween.is_running()):
		if map.get_cell_source_id(2,current_cell) == -1:
			move_in_direction(previous_direction)
			void_count += 1
			if void_count > MAX_VOID:
				emit_signal("requesting_restart")
				queue_free()
		else:
			void_count = clamp(void_count - .01, 0, MAX_VOID)
		modulate = lerp(Color.WHITE,Color(1,1,1,0),void_count/MAX_VOID)
	if _handle_inputs():
		recaculate_line_of_sight()
	

func _handle_inputs() -> bool:
	@warning_ignore(narrowing_conversion)
	var input : Vector2i = Vector2i(Input.get_axis("ui_left","ui_right"), Input.get_axis("ui_up","ui_down"))
	if (!tween || !tween.is_running()) && \
		input != Vector2i.ZERO && \
		(input.x == 0) != (input.y == 0) && \
		map.get_cell_source_id(1,current_cell + input) == -1:
		move_in_direction(input)
		return true
	return false

func move_in_direction(direction : Vector2i):
	current_cell += direction
	tween = create_tween()
	var _tween = tween.tween_property(self,"position",position + direction * map.tile_set.tile_size * 1.0,.2)
	previous_direction = direction
	if map.get_cell_source_id(0,current_cell) == WIN_TILE_ID:
		var _signal = emit_signal("won")

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
