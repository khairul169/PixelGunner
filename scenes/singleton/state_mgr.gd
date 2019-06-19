extends Node

var player = {
	'weapon': null
};

func _ready() -> void:
	PlayerWeapon.check_weapon();

func goto_mainmenu() -> void:
	get_tree().change_scene("res://scenes/main_menu.tscn");
