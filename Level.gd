extends TileMap

const PLAYER_START_CELL_ID := 4
const WALL_CELL_ID := 0
const EXIT_CELL_ID := 3

@export var player_scene : PackedScene
@export var occluder_scene : PackedScene
@export var ping_scene : PackedScene
@export var on_color : Color

# Called when the node enters the scene tree for the first time.
func _ready():
	var player : Player
	for cell in get_used_cells(0):
		var cell_id = get_cell_source_id(0,cell)
		if cell_id == PLAYER_START_CELL_ID:
			player = spawn_player(cell)
			erase_cell(0,cell)
	for cell in get_used_cells(1):
		var cell_id = get_cell_source_id(1,cell)
		if cell_id == EXIT_CELL_ID:
			spawn_ping(cell, player)
		if cell_id not in Player.OCCLUDER_EXCEPTIONS:
			spawn_occluder(cell,cell_id)
			get_cell_tile_data(1,cell).modulate = Color.DARK_GRAY

func spawn_player(cell : Vector2i) -> Player:
	var player : Player = player_scene.instantiate()
	player.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	player.top_level = true
	player.current_cell = cell
	add_child(player)
	return player

func spawn_occluder(cell : Vector2i, cell_id : int):
	var occluder : StaticBody2D = occluder_scene.instantiate()
	occluder.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	occluder.name = str(cell)
	add_child(occluder)

func spawn_ping(cell : Vector2i, player : Player):
	var ping = ping_scene.instantiate()
	ping.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	add_child(ping)
