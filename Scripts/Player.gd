class_name Player
extends Veiwer

const WALL_EXCEPTIONS := [-1,WIN_TILE_ID,Veiwer.SCORCH_TILE_ID]
const FLOOR_LAYER := 0
const FLOOR_TERRAIN_ID := 2
const SCORCH_TERRAIN_ID := 3
const MAX_VOID := 5

@onready var light : PointLight2D = $PointLight2D
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2d
@onready var won_sound : AudioStreamPlayer2D = $WonSound

var current_cell : Vector2i
var tween : Tween
var previous_direction : Vector2i
var in_sight_set : PackedVector2Array
var out_of_sight_exceptions : PackedVector2Array
var void_count := 0.0

signal moved(new_cell)
signal won
signal lost
signal saw_exit

func _ready():
	reset(current_cell,map)

func _process(_delta):
	if map && (do_void_check() || _handle_inputs()):
		await tween.finished
		@warning_ignore(return_value_discarded)
		emit_signal("moved",current_cell)
		if map:
			recaculate_line_of_sight()

func reset(_current_cell : Vector2i, _map : TileMap):
	in_sight_set = PackedVector2Array()
	void_count = 0
	previous_direction = Vector2i.ZERO
	if tween:
		tween.stop()
	light.energy = 0
	@warning_ignore(return_value_discarded)
	create_tween().tween_property(light,"energy",1,.2)
	current_cell = _current_cell
	map = _map
	tween = create_tween()
	@warning_ignore(return_value_discarded)
	tween.tween_property(self,\
	"position",self.current_cell * map.tile_set.tile_size * 1.0 + map.tile_set.tile_size/2.0,.4)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	AudioServer.set_bus_mute(1,true)
	await tween.finished
	await intro()
	recaculate_line_of_sight()

func intro():
	sprite.animation = "enter"
	await sprite.animation_finished
	sprite.animation = "default"

func do_void_check() -> bool:
	if void_count > MAX_VOID:
		return true
	modulate = lerp(Color.WHITE,Color(1,1,1,0),void_count/MAX_VOID)
	var current_cell_id = map.get_cell_source_id(FLOOR_LAYER,current_cell)
	if current_cell_id != -1:
		void_count = clamp(void_count - .1, 0, MAX_VOID)
	elif (!tween || !tween.is_running()):
		var next_cell = current_cell + previous_direction
		var next_cell_id = map.get_cell_source_id(WALL_LAYER,next_cell)
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
		map.get_cell_source_id(WALL_LAYER,current_cell + input) in WALL_EXCEPTIONS:
		move_in_direction(input)
		return true
	return false

func move_in_direction(direction : Vector2i):
	current_cell += direction
	tween = create_tween()
	@warning_ignore(return_value_discarded)
	tween.set_parallel(true)
	var _rotor = tween.tween_property(sprite,"rotation",Vector2(direction).angle() - PI/2,.1)
	var _tween = tween.tween_property(self,"position",position + direction * map.tile_set.tile_size * 1.0,.2)
	previous_direction = direction
	if map.get_cell_source_id(WALL_LAYER,current_cell) == WIN_TILE_ID:
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
				map.get_cell_tile_data(WALL_LAYER,cell).modulate = map.on_color
		elif Vector2(cell) in in_sight_set && Vector2(cell) not in out_of_sight_exceptions:
			if !destory_cell(cell):
				break

func destory_cell(cell : Vector2i) -> bool:
	var cell_id = map.get_cell_source_id(1,cell)
	map.erase_cell(WALL_LAYER,cell)
	if cell_id == WIN_TILE_ID:
		@warning_ignore(return_value_discarded)
		emit_signal("lost")
		return false
	var node = map.get_node_or_null(str(cell))
	if node:
		node.queue_free()
		AudioServer.set_bus_mute(1,false)
	map.set_cells_terrain_connect(FLOOR_LAYER,[cell],0,FLOOR_TERRAIN_ID)
	map.force_update(FLOOR_LAYER)
	for surrounding_cell in map.get_used_cells(FLOOR_LAYER):
		map.get_cell_tile_data(FLOOR_LAYER,surrounding_cell).modulate = map.on_color
	return true

func _on_won():
	sprite.animation = "exit"
	won_sound.play()
	map = null

func _on_lost():
	@warning_ignore(return_value_discarded)
	create_tween().tween_property(light,"energy",0,1)
	map = null
