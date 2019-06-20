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

# vars
var armory;
var rotating_weapon: bool;
var stats_label = {};

func _ready() -> void:
	load_stats();
	call_deferred("load_weapon");

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton):
		if (event.pressed && weapon_prev.get_global_rect().has_point(event.position)):
			rotating_weapon = true;
		else:
			rotating_weapon = false;
	
	if (event is InputEventMouseMotion):
		if (rotating_weapon):
			_rotate_weapon(event.relative.x);

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
	var weapon_list = [
		PlayerWeapon.WEAPON_PISTOL,
		PlayerWeapon.WEAPON_RIFLE,
	];
	
	if (armory):
		armory.set_slot_value(weapon_list.size(), 20);
	
	_switch_weapon(weapon_list[0]);
	
	var item_container = $container/items;
	for i in item_container.get_children():
		i.queue_free();
	
	var item_scene = load("res://scenes/main_menu/weapon_item.tscn");
	for i in weapon_list:
		var wpn = PlayerWeapon.get_weapon(i);
		if (not wpn):
			continue
		
		var item = item_scene.instance();
		item_container.add_child(item);
		
		item.connect("pressed", self, "_switch_weapon", [i]);
		item.get_node('title').text = wpn.name;
		item.get_node('used').visible = (state_mgr.player.weapon == i);
		
		var item_pict = load("res://sprites/weapon/" + wpn.alias + ".png");
		if (item_pict):
			item.get_node('item').texture = item_pict;

func _switch_weapon(id: int) -> void:
	set_weapon(id);
	$content/AnimationPlayer.play("fade_in");
	$content/AnimationPlayer.seek(0.0);

func _rotate_weapon(rel: float) -> void:
	scene.rotate_object(rel);

func set_weapon(id: int) -> void:
	var wpn = PlayerWeapon.get_weapon(id);
	if (not wpn):
		return;
	
	$content/weapon_title/wpn_name.text = wpn.name;
	
	var stats = PlayerWeapon.calculate_stats(id, 1, 0.0);
	
	set_weapon_stats({
		STATS_DMG: int(stats.damage),
		STATS_ROF: int(stats.rof),
		STATS_ACC: int(stats.accuracy),
		STATS_CLIP: wpn.clip,
		STATS_AP: 0,
		STATS_KNOCKBACK: int(stats.knockback),
		STATS_SLOWNESS: str(int(stats.slowness * 100), "%")
	});
	
	scene.set_object(wpn.alias);

func set_weapon_stats(stats: Dictionary) -> void:
	for key in stats:
		if (stats_label.has(key)):
			stats_label[key].text = str(stats[key]);
