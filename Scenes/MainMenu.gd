extends Node2D

@export var first_scene :PackedScene
@onready var animator :AnimationPlayer = $Logo/AnimationPlayer

func _on_play_pressed():
	get_tree().change_scene_to_packed(first_scene)


func _on_options_pressed():
	var options = load("res://Scenes/Options.tscn")
	animator.play("Closer")
	await animator.animation_finished
	get_tree().change_scene_to_packed(options)


func _on_exit_pressed():
	get_tree().quit()
