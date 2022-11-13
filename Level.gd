extends TileMap

const PLAYER_START_CELL_ID := 4
const WALL_CELL_ID := 0

@export var player_scene : PackedScene
@export var occluder_scene : PackedScene
@export var ping_scene : PackedScene
@export var next_level : PackedScene
@export var on_color : Color

@onready var restart_label : Label = $"CanvasLayer/Restart Text"

var camera_list := []
var ping : GPUParticles2D

# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_utility_objects()
	spawn_wall_objects()

func _unhandled_input(event):
	if event.is_action_pressed("ui_restart"):
		@warning_ignore(return_value_discarded)
		get_tree().reload_current_scene()

func spawn_utility_objects():
	var player : Player
	for cell in get_used_cells(0):
		var cell_id = get_cell_source_id(0,cell)
		if cell_id == PLAYER_START_CELL_ID:
			player = spawn_player(cell)
			@warning_ignore(return_value_discarded)
			player.connect("won",_on_player_win)
			@warning_ignore(return_value_discarded)
			player.connect("lost",_on_player_lose)
			erase_cell(0,cell)

func spawn_wall_objects():
	for cell in get_used_cells(1):
		var cell_id = get_cell_source_id(1,cell)
		if cell_id == Player.WIN_TILE_ID:
			spawn_ping(cell)
		if cell_id not in Player.OCCLUDER_EXCEPTIONS:
			spawn_occluder(cell)
			get_cell_tile_data(1,cell).modulate = Color.DARK_GRAY

func spawn_player(cell : Vector2i) -> Player:
	var player : Player = player_scene.instantiate()
	player.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	player.top_level = true
	player.current_cell = cell
	add_child(player)
	return player

func spawn_occluder(cell : Vector2i):
	var occluder : StaticBody2D = occluder_scene.instantiate()
	occluder.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	occluder.name = str(cell)
	add_child(occluder)

func spawn_ping(cell : Vector2i):
	ping = ping_scene.instantiate()
	ping.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	add_child(ping)

func _on_player_win():
	@warning_ignore(return_value_discarded)
	get_tree().change_scene_to_packed(next_level)

func _on_player_lose():
	ping.visible = false
	create_tween().tween_property(restart_label,"modulate", Color.WHITE,3)

func _on_player_saw_exit():
	ping.visible = false
