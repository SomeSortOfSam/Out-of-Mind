extends TileMap

const PLAYER_START_CELL_ID := 4
const WALL_CELL_ID := 0

@export var player_scene : PackedScene
@export var occluder_scene : PackedScene
@export var ping_scene : PackedScene
@export var next_level : PackedScene
@export var on_color : Color

@onready var restart_label : Label = $"CanvasLayer/Restart Text"
@onready var camera : Camera2D = $Camera2D

var camera_list := []
var ping : GPUParticles2D

# Called when the node enters the scene tree for the first time.
func _ready():
	modulate = Color(1,1,1,0)
	start_camera_change()
	spawn_wall_objects()
	spawn_utility_objects()
	@warning_ignore(return_value_discarded)
	create_tween().tween_property(self,"modulate",Color.WHITE,1.5).set_ease(Tween.EASE_IN)

func _unhandled_input(event):
	if event.is_action_pressed("ui_restart"):
		@warning_ignore(return_value_discarded)
		get_tree().reload_current_scene()

func start_camera_change():
	@warning_ignore(shadowed_variable)
	var camera = get_node_or_null("../Camera2D")
	if !camera:
		remove_child(self.camera)
		$"..".call_deferred("add_child",self.camera)
		camera = self.camera
	@warning_ignore(return_value_discarded)
	create_tween().tween_property(camera,"position",self.camera.position,1.5)
	if camera != self.camera:
		self.camera.queue_free()

func spawn_utility_objects():
	for cell in get_used_cells(0):
		var cell_id = get_cell_source_id(0,cell)
		if cell_id == PLAYER_START_CELL_ID:
			spawn_player(cell)
			erase_cell(0,cell)

func spawn_wall_objects():
	for cell in get_used_cells(1):
		var cell_id = get_cell_source_id(1,cell)
		if cell_id == Player.WIN_TILE_ID:
			spawn_ping(cell)
		if cell_id not in Player.OCCLUDER_EXCEPTIONS:
			spawn_occluder(cell)
			get_cell_tile_data(1,cell).modulate = Color.DARK_GRAY

func spawn_player(cell : Vector2i):
	var player : Player = get_node_or_null("../Player")
	if !player:
		player = player_scene.instantiate()
		$"..".call_deferred("add_child",player)
		player.call_deferred("reset", cell, self)
	else:
		player.reset(cell, self)
	@warning_ignore(return_value_discarded)
	player.connect("won",_on_player_win)
	@warning_ignore(return_value_discarded)
	player.connect("lost",_on_player_lose)
	@warning_ignore(return_value_discarded)
	player.connect("saw_exit",_on_player_saw_exit)

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
	await get_tree().process_frame
	var tween = create_tween()
	@warning_ignore(return_value_discarded)
	tween.tween_property(self,"modulate",Color(1,1,1,0),1).set_ease(Tween.EASE_OUT)
	await tween.finished
	@warning_ignore(return_value_discarded)
	get_tree().change_scene_to_packed(next_level)

func _on_player_lose():
	ping.visible = false
	await get_tree().process_frame
	@warning_ignore(return_value_discarded)
	create_tween().tween_property(restart_label,"modulate", Color.WHITE,3)
	@warning_ignore(return_value_discarded)
	create_tween().tween_property(self,"modulate",Color(1,1,1,0),1.5).set_ease(Tween.EASE_OUT)

func _on_player_saw_exit():
	#ping.visible = false
	pass
