extends TileMap

const PLAYER_START_CELL_ID := 4
const CAMERA_CELL_ID := 6
const WALL_CELL_ID := 0

@export var player_scene : PackedScene
@export var occluder_scene : PackedScene
@export var camera_scene : PackedScene
@export var ping_scene : PackedScene
@export var next_level : PackedScene
@export var on_color : Color

@onready var restart_label : Label = $"CanvasLayer/Restart Text"
@onready var camera : Camera2D = $Camera2D

var ping : GPUParticles2D
var player : Player

# Called when the node enters the scene tree for the first time.
func _ready():
	modulate = Color(1,1,1,0)
	start_camera_change()
	spawn_wall_objects()
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
	@warning_ignore(return_value_discarded)
	create_tween().tween_property(camera,"zoom",self.camera.zoom,1.5)
	if camera != self.camera:
		self.camera.queue_free()
	camera.current = true

func spawn_wall_objects():
	for cell in get_used_cells(Veiwer.WALL_LAYER):
		match get_cell_source_id(Veiwer.WALL_LAYER,cell):
			PLAYER_START_CELL_ID:
				spawn_player(cell)
				erase_cell(Veiwer.WALL_LAYER,cell)
			CAMERA_CELL_ID:
				call_deferred("spawn_camera",cell)
				erase_cell(Veiwer.WALL_LAYER,cell)
			Player.WIN_TILE_ID:
				spawn_ping(cell)
			var cell_id:
				if cell_id not in Player.OCCLUDER_EXCEPTIONS:
					spawn_occluder(cell)
					get_cell_tile_data(Veiwer.WALL_LAYER,cell).modulate = Color.DARK_GRAY
					erase_cell(Player.FLOOR_LAYER,cell)
					force_update(Player.FLOOR_LAYER)

func spawn_player(cell : Vector2i):
	player = get_node_or_null("../Player")
	if !player:
		player = player_scene.instantiate()
		$"..".call_deferred("add_child",player)
		player.current_cell = cell
		player.map = self
	else:
		player.reset(cell, self)
	@warning_ignore(return_value_discarded)
	player.connect("won",_on_player_win,1)
	@warning_ignore(return_value_discarded)
	player.connect("lost",_on_player_lose,1)
	@warning_ignore(return_value_discarded)
	player.connect("saw_exit",_on_player_saw_exit)

func spawn_occluder(cell : Vector2i):
	var occluder : StaticBody2D = occluder_scene.instantiate()
	occluder.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	occluder.name = str(cell)
	add_child(occluder)

func spawn_camera(cell : Vector2i):
	@warning_ignore(shadowed_variable)
	var camera : Camera = camera_scene.instantiate()
	camera.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	var tile_data := get_cell_tile_data(0,cell)
	if tile_data:
		if tile_data.flip_h:
			camera.scale.x = -1
		if tile_data.flip_v:
			camera.scale.y = -1
		if tile_data.transpose:
			camera.rotation = -PI/2
	camera.map = self
	camera.cell = cell
	add_child(camera)
	@warning_ignore(return_value_discarded)
	camera.connect("turned_on",_on_camera_turned_on)
	@warning_ignore(return_value_discarded)
	player.connect("moved",camera._on_player_moved)

func spawn_ping(cell : Vector2i):
	ping = ping_scene.instantiate()
	ping.position = cell * tile_set.tile_size * 1.0 + tile_set.tile_size/2.0
	add_child(ping)

func _on_player_win():
	var tween = create_tween()
	@warning_ignore(return_value_discarded)
	tween.tween_property(self,"modulate",Color(1,1,1,0),1).set_ease(Tween.EASE_OUT)
	await tween.finished
	@warning_ignore(return_value_discarded)
	get_tree().change_scene_to_packed(next_level)

func _on_player_lose():
	ping.visible = false
	@warning_ignore(return_value_discarded)
	create_tween().tween_property(restart_label,"modulate", Color.WHITE,3)
	@warning_ignore(return_value_discarded)
	create_tween().tween_property(self,"modulate",Color(1,1,1,0),1.5).set_ease(Tween.EASE_OUT)

func _on_player_saw_exit():
	ping.visible = false

func _on_camera_turned_on(seen_tiles : PackedVector2Array):
	player.out_of_sight_exceptions.append_array(seen_tiles)