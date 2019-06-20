extends Control

# refs
onready var scene = $content.find_node('scene');
onready var weapon_prev = $content/weapon_prev;
onready var stats_container = $content/weapon_stats/container;

# vars
var rotating_weapon: bool;

func _ready() -> void:
	var stats_item = stats_container.get_child(0);
	stats_container.remove_child(stats_item);
	
	var stats = [
		["damage", 10],
		["firing rate", 300],
		["accuracy", 10],
		["clip", 30],
		["armor penetration", 100],
		["knockback", 8.0],
		["slowness", 0.5]
	];
	
	for i in stats:
		var instance = stats_item.duplicate();
		stats_container.add_child(instance);
		
		instance.get_node('title').text = str(i[0]);
		instance.get_node('value').text = str(i[1]);
	
	stats_item.free();

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton):
		if (event.pressed && weapon_prev.get_global_rect().has_point(event.position)):
			rotating_weapon = true;
		else:
			rotating_weapon = false;
	
	if (event is InputEventMouseMotion):
		if (rotating_weapon):
			_rotate_weapon(event.relative.x);

func _rotate_weapon(rel: float) -> void:
	scene.rotate_object(rel);
