extends Control

# refs
onready var background_scene = $background.find_node('background');
onready var content_anims = $content/AnimationPlayer;

func _ready() -> void:
	# load navigation
	setup_navigation();
	
	# play panel
	$content/container.hide();
	$content/container/play/single.connect("pressed", self, "_play");
	
	# delay timer
	yield(get_tree().create_timer(0.5), "timeout");
	
	# load default panel
	switch_panel('play');

func _nav_pressed(btn: String) -> void:
	if (!$content/container.has_node(btn)):
		return;
	
	if (btn == 'play'):
		background_scene.camera_transform = background_scene.find_node('camera_home').transform;
	else:
		background_scene.camera_transform = background_scene.find_node('camera_armory').transform;
	
	switch_panel(btn);

func _play() -> void:
	state_mgr.reset_game();
	get_tree().change_scene("res://scenes/game.tscn");

func setup_navigation() -> void:
	# navigation container
	var container = $footer/nav;
	var nav_item = container.get_child(0);
	container.remove_child(nav_item);
	
	var navigation_list = {
		'play': "Play",
		'armory': "Armory",
		'quest': "Quest",
		'community': "Community"
	};
	
	for key in navigation_list:
		# navigation button title
		var value = navigation_list[key];
		
		# instance button
		var instance = nav_item.duplicate();
		container.add_child(instance);
		
		if (key == 'armory'):
			instance.rect_min_size.x = 180;
		
		if (key == 'community'):
			instance.rect_min_size.x = 220;
		
		instance.get_node('label').text = str(value).to_upper();
		instance.connect("pressed", self, "_nav_pressed", [key]);
	
	# free navigation item template
	nav_item.free();

func switch_panel(panel: String) -> void:
	var container = $content/container;
	if (!container.has_node(panel)):
		return;
	
	for i in container.get_children():
		i.visible = (i.name == panel);
	
	$content/AnimationPlayer.play("fade_in");
	$content/AnimationPlayer.seek(0.0);
