extends Node

func _ready() -> void:
	if (OS.get_name() == 'Android'):
		Engine.target_fps = 30;
