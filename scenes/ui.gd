extends Control

# reference
onready var controller = $controller;
onready var button_attack = $action_button/attack;
onready var button_reload = $action_button/reload;

func _ready() -> void:
	$menu_btn.connect("pressed", self, "_open_menu");

func _open_menu() -> void:
	state_mgr.goto_mainmenu();

func set_reloadbutton_clip(clip: int) -> void:
	if (!button_reload):
		return;
	
	if (clip >= 0):
		button_reload.get_node('clip').visible = true;
		button_reload.get_node('clip').text = str(clip);
	else:
		button_reload.get_node('clip').visible = false;
