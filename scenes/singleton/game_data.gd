extends Node

signal data_updated();

# classes
class Armory extends Reference:
	var weapon_list := [];
	var current_wpn := -1;

# vars
var player_armory: Armory;

func _ready() -> void:
	# initialize data
	player_armory = Armory.new();
	
	# simulate load time
	# yield(get_tree().create_timer(0.1), "timeout");
	
	player_armory.weapon_list.append({
		'id': Weapon.WEAPON_PISTOL,
		'level': 1,
		'enhancement': 0.0,
		'upgrade': 0
	});
	player_armory.weapon_list.append({
		'id': Weapon.WEAPON_RIFLE,
		'level': 1,
		'enhancement': 0.0,
		'upgrade': 0
	});
	player_armory.current_wpn = 1;
	
	# data fetched
	call_deferred("emit_signal", "data_updated");

func get_weapon_list() -> Array:
	return player_armory.weapon_list;

func get_weapon_data(id: int):
	if (id < 0):
		id = player_armory.current_wpn;
	if (id >= 0 && id < player_armory.weapon_list.size()):
		return player_armory.weapon_list[id];
	return null;

func set_player_weapon(id: int) -> void:
	player_armory.current_wpn = id;
	emit_signal("data_updated");

func get_player_weapon() -> int:
	return player_armory.current_wpn;

func get_weapon_slot() -> int:
	return 20;
