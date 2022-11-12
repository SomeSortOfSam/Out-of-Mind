extends TileMap

const PLAYER_START_CELL_ID := 4
const WALL_CELL_ID := 0
const EXIT_CELL_ID := 3

@export var player_scene : PackedScene
@export var occluder_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	for cell in get_used_cells(0):
		var cell_id = get_cell_source_id(0,cell)
		if cell_id == PLAYER_START_CELL_ID:
			spawn_player(cell)
			set_cell(0,cell)
	for cell in get_used_cells(1):
		var cell_id = get_cell_source_id(1,cell)
		if cell_id == WALL_CELL_ID:
			spawn_occluder(cell)

func spawn_player(cell : Vector2i):
	var player : Player = player_scene.instantiate()
	player.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	player.top_level = true
	player.current_cell = cell
	add_child(player)

func spawn_occluder(cell : Vector2i):
	var occluder : LightOccluder2D = occluder_scene.instantiate()
	occluder.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	#occluder.top_level = true
	add_child(occluder)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass