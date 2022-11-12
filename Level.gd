extends TileMap

const PLAYER_START_CELL = 4
const EXIT_CELL = 3

@export var player_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	for cell in get_used_cells(0):
		if get_cell_source_id(0,cell) == PLAYER_START_CELL:
			spwan_player(cell)

func spwan_player(cell : Vector2i):
	var player : Node2D = player_scene.instantiate()
	player.position = cell * tile_set.cell_size + tile_set.cell_size/2.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
