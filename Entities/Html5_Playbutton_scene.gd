extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.get_name() == "Windows":
		# Godot 4 cannot swap the scene while the tree is still building it.
		_goto_title.call_deferred()

	pass # Replace with function body.

func _input(event):
	if event:
		if event.is_pressed():
			_goto_title.call_deferred()
	pass

func _goto_title():
	get_tree().change_scene_to_file("res://Scenes/Title_scene.tscn")
