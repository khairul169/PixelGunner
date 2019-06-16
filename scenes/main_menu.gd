extends Control

var current_panel;

func _ready() -> void:
	for i in $header/nav.get_children():
		if (i is Button):
			i.connect("pressed", self, "_nav_pressed", [i]);
	
	# play panel
	$panel/container/play/single.connect("pressed", self, "_play");

func _nav_pressed(btn: Control) -> void:
	if (btn.name == 'quit'):
		get_tree().quit();
	else:
		switch_panel(btn.name);

func switch_panel(panel) -> void:
	# dont switch if current panel is same
	if (current_panel == panel):
		return;
	
	# check if container has panel node
	var container = $panel/container;
	if (!container.has_node(panel)):
		return;
	
	# fade out panel
	$panel/AnimationPlayer.play("fade_out");
	$panel/AnimationPlayer.seek(0.0);
	
	# wait for panel animation
	yield(get_tree().create_timer(0.2), "timeout");
	
	# hide all panel
	for i in container.get_children():
		i.hide();
	
	# show destination panel
	container.get_node(panel).show();
	
	# fade in panel
	$panel/AnimationPlayer.play("fade_in");
	$panel/AnimationPlayer.seek(0.0);
	
	current_panel = panel;

func _play() -> void:
	get_tree().change_scene("res://scenes/game.tscn");
