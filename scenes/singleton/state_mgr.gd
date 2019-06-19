extends Node

var player = {
	'weapon': null
};

func _ready() -> void:
	pass

func goto_mainmenu() -> void:
	get_tree().change_scene("res://scenes/main_menu.tscn");
