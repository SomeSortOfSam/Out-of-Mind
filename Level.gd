extends TileMap

const PLAYER_START_CELL := 4
const EXIT_CELL := 3

@export var player_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	for cell in get_used_cells(0):
		if get_cell_source_id(0,cell) == PLAYER_START_CELL:
			spwan_player(cell)

func spwan_player(cell : Vector2i):
	var player : Player = player_scene.instantiate()
	player.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	player.top_level = true
	player.current_cell = cell
	add_child(player)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
