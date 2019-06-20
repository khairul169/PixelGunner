extends Control

var weapon_list = [
	PlayerWeapon.WEAPON_PISTOL,
	PlayerWeapon.WEAPON_RIFLE
];

func _ready() -> void:
	return;
	"""
	for i in $panel/container/items.get_children():
		i.queue_free();
	
	var item_scene = load("res://scenes/main_menu/weapon_item.tscn");
	for i in range(10):
		for i in weapon_list:
			var item = item_scene.instance();
			$panel/container/items.add_child(item);
			
			item.connect("pressed", self, "_test", [i]);
			item.get_node('title').text = PlayerWeapon.get_weapon(i).name;
	"""

func _test(item) -> void:
	state_mgr.player.weapon = item;
	#print('jajja ', item.name);
