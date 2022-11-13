class_name Player
extends Node2D

const WIN_TILE_ID := 3
const GLASS_TILE_ID := 1
const WALL_EXCEPTIONS := [-1,WIN_TILE_ID]
const OCCLUDER_EXCEPTIONS := [GLASS_TILE_ID,WIN_TILE_ID]
const MAX_VOID := 5

@onready var raycast : RayCast2D = $RayCast2D
@onready var light : PointLight2D = $PointLight2D

var map : TileMap
var current_cell : Vector2i
var tween : Tween
var previous_direction : Vector2i
var in_sight_set : PackedVector2Array
var void_count := 0.0

signal won
signal lost
signal saw_exit

func _process(_delta):
	if map && (do_void_check() || _handle_inputs()):
		await tween.finished
		if map:
			recaculate_line_of_sight()

func reset(current_cell : Vector2i, map : TileMap):
	in_sight_set = PackedVector2Array()
	void_count = 0
	previous_direction = Vector2i.ZERO
	if tween:
		tween.stop()
	light.energy = 0
	create_tween().tween_property(light,"energy",1,.2)
	self.current_cell = current_cell
	self.map = map
	tween = create_tween()
	tween.tween_property(self,\
	"position",self.current_cell * map.tile_set.tile_size * 1.0 + map.tile_set.tile_size/2.0,.4)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func do_void_check() -> bool:
	if void_count > MAX_VOID:
		return true
	modulate = lerp(Color.WHITE,Color(1,1,1,0),void_count/MAX_VOID)
	var current_cell_id = map.get_cell_source_id(2,current_cell)
	if current_cell_id != -1:
		void_count = clamp(void_count - .1, 0, MAX_VOID)
	elif (!tween || !tween.is_running()):
		var next_cell = current_cell + previous_direction
		var next_cell_id = map.get_cell_source_id(1,next_cell)
		move_in_direction(previous_direction if next_cell_id in WALL_EXCEPTIONS else -previous_direction )
		void_count += 1
		if void_count > MAX_VOID:
			@warning_ignore(return_value_discarded)
			emit_signal("lost")
		return true
	return false

func _handle_inputs() -> bool:
	@warning_ignore(narrowing_conversion)
	var input : Vector2i = Vector2i(Input.get_axis("ui_left","ui_right"), Input.get_axis("ui_up","ui_down"))
	if (!tween || !tween.is_running()) && \
		input != Vector2i.ZERO && \
		(input.x == 0) != (input.y == 0) && \
		map.get_cell_source_id(1,current_cell + input) in WALL_EXCEPTIONS:
		move_in_direction(input)
		return true
	return false

func move_in_direction(direction : Vector2i):
	current_cell += direction
	tween = create_tween()
	var _tween = tween.tween_property(self,"position",position + direction * map.tile_set.tile_size * 1.0,.2)
	previous_direction = direction
	if map.get_cell_source_id(1,current_cell) == WIN_TILE_ID:
		await tween.finished
		var _signal = emit_signal("won")

func recaculate_line_of_sight():
	for cell in map.get_used_cells(1):
		if get_is_visible(cell):
			@warning_ignore(return_value_discarded)
			in_sight_set.append(cell)
			var cell_id = map.get_cell_source_id(1,cell)
			if cell_id == WIN_TILE_ID:
				@warning_ignore(return_value_discarded)
				emit_signal("saw_exit")
			if cell_id not in OCCLUDER_EXCEPTIONS:
				map.get_cell_tile_data(1,cell).modulate = map.on_color
		elif Vector2(cell) in in_sight_set:
			if !destory_cell(cell):
				break

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

func destory_cell(cell : Vector2i) -> bool:
	var cell_id = map.get_cell_source_id(1,cell)
	map.erase_cell(1,cell)
	if cell_id == WIN_TILE_ID:
		@warning_ignore(return_value_discarded)
		emit_signal("lost")
		return false
	var node = map.get_node_or_null(str(cell))
	if node:
		node.queue_free()
	map.set_cells_terrain_connect(2,[cell],0,2)
	map.force_update(2)
	return true

func _on_won():
	await get_tree().process_frame
	map = null

func _on_lost():
	create_tween().tween_property(light,"energy",0,1)
	await get_tree().process_frame
	map = null
