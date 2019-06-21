extends Control

enum {
	STATS_DMG,
	STATS_ROF,
	STATS_ACC,
	STATS_CLIP,
	STATS_AP,
	STATS_KNOCKBACK,
	STATS_SLOWNESS
};

# refs
onready var scene = $content.find_node('scene');
onready var weapon_prev = $content/weapon_prev;
onready var stats_container = $content/weapon_stats/container;
onready var btn_use = $content/action/container/use;

# vars
var armory;
var rotating_weapon: bool;
var stats_label = {};
var current_wpn = -1;

func _ready() -> void:
	call_deferred("load_weapon");
	load_stats();
	
	var player_wpn = GameData.get_player_weapon();
	switch_weapon(player_wpn);
	
	GameData.connect("data_updated", self, "_data_updated");
	btn_use.connect("pressed", self, "_use_wpn");

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton):
		if (event.pressed && weapon_prev.get_global_rect().has_point(event.position)):
			rotating_weapon = true;
		else:
			rotating_weapon = false;
	
	if (event is InputEventMouseMotion):
		if (rotating_weapon):
			_rotate_weapon(event.relative.x);

func _data_updated() -> void:
	# update weapon list
	load_weapon();
	
	var player_wpn = GameData.get_player_weapon();
	if (current_wpn < 0):
		switch_weapon(player_wpn);
	else:
		switch_weapon(current_wpn);

func load_stats() -> void:
	var stats_item = stats_container.get_child(0);
	stats_container.remove_child(stats_item);
	
	var stats = [
		[STATS_DMG, "damage", 10],
		[STATS_ROF, "firing rate", 300],
		[STATS_ACC, "accuracy", 10],
		[STATS_CLIP, "clip", 30],
		[STATS_AP, "armor penetration", 100],
		[STATS_KNOCKBACK, "knockback", 8.0],
		[STATS_SLOWNESS, "slowness", 0.5]
	];
	
	for i in stats:
		# instance stats item
		var instance = stats_item.duplicate();
		stats_container.add_child(instance);
		
		# update stats label
		stats_label[i[0]] = instance.get_node('value');
		
		# set value
		instance.get_node('value').text = str(i[2]);
		instance.get_node('title').text = str(i[1]);
	
	stats_item.free();

func load_weapon() -> void:
	var item_container = $container/items;
	for i in item_container.get_children():
		i.queue_free();
	
	var item_scene = load("res://scenes/main_menu/weapon_item.tscn");
	var weapon_list = GameData.get_weapon_list();
	
	if (armory):
		armory.set_slot_value(weapon_list.size(), GameData.get_weapon_slot());
	
	for i in range(weapon_list.size()):
		var weapon = weapon_list[i];
		var wpn_data = Weapon.get_weapon(weapon.id);
		if (not wpn_data):
			continue
		
		var item = item_scene.instance();
		item_container.add_child(item);
		
		item.connect("pressed", self, "switch_weapon", [i]);
		item.get_node('title').text = wpn_data.name;
		item.get_node('used').visible = (current_wpn == i);
		
		var item_pict = load("res://sprites/weapon/" + wpn_data.alias + ".png");
		if (item_pict):
			item.get_node('item').texture = item_pict;

func switch_weapon(id: int) -> void:
	if (id < 0):
		$content.hide();
		return;
	
	var weapon = GameData.get_weapon_data(id);
	if (not weapon):
		return;
	
	# set current weapon
	current_wpn = id;
	
	# play animation
	$content.show();
	$content/AnimationPlayer.play("fade_in");
	$content/AnimationPlayer.seek(0.0);
	
	# change weapon detail
	set_weapon(weapon);
	
	# action button
	btn_use.disabled = (GameData.get_player_weapon() == id);

func _use_wpn() -> void:
	GameData.set_player_weapon(current_wpn);

func _rotate_weapon(rel: float) -> void:
	scene.rotate_object(rel);

func set_weapon(weapon: Dictionary) -> void:
	var wpn = Weapon.get_weapon(weapon.id);
	if (not wpn):
		return;
	
	$content/weapon_title/wpn_name.text = wpn.name;
	$content/weapon_title/level.text = str('Lv ', int(weapon.level));
	
	var stats = Weapon.get_stats(weapon);
	
	set_weapon_stats({
		STATS_DMG: int(stats.damage),
		STATS_ROF: int(stats.rof),
		STATS_ACC: int(stats.accuracy),
		STATS_CLIP: stats.clip,
		STATS_AP: int(stats.armorp),
		STATS_KNOCKBACK: int(stats.knockback),
		STATS_SLOWNESS: str(int(stats.slowness * 100), "%")
	});
	
	scene.set_object(wpn.alias);

func set_weapon_stats(stats: Dictionary) -> void:
	for key in stats:
		if (stats_label.has(key)):
			stats_label[key].text = str(stats[key]);
