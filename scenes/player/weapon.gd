extends Reference
class_name PlayerWeapon

enum {
	CLASS_HG = 0,
	CLASS_AR,
	CLASS_SMG,
	CLASS_SR,
	CLASS_SG
};

enum {
	WEAPON_PISTOL = 1,
	WEAPON_RIFLE,
	
	WEAPON_ALL
};

const weapon_data = {
	
	# pistol
	WEAPON_PISTOL: {
		'wpn_class': CLASS_HG,
		'damage': 30.0,
		'rof': 60,
		'accuracy': 20.0,
		'clip': 12,
		'knockback': 10.0,
		'slowness': 0.2
	},
	
	# rifle
	WEAPON_RIFLE: {
		'wpn_class': CLASS_AR,
		'damage': 10.0,
		'rof': 300,
		'accuracy': 10.0,
		'clip': 30,
		'knockback': 8.0,
		'slowness': 0.5
	}
};

static func get_weapon(id: int):
	if (id <= 0 || id >= WEAPON_ALL || !weapon_data.has(id)):
		return null;
	return weapon_data[id];
