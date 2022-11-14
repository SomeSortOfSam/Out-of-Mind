extends Node2D

@onready var animator :AnimationPlayer = $AnimationPlayer

func _on_back_pressed():
	var menu = load("res://Scenes/MainMenu.tscn")
	animator.play_backwards("Opener")
	await animator.animation_finished
	get_tree().change_scene_to_packed(menu)
