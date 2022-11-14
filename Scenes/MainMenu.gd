extends Node2D

@export var first_scene :PackedScene

func _on_play_pressed():
	get_tree().change_scene_to_packed(first_scene)


func _on_options_pressed():
	pass # Replace with function body.


func _on_exit_pressed():
	get_tree().quit()
