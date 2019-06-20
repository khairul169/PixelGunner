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
		'alias': 'pistol',
		'name': 'Pistol',
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
		'alias': 'rifle',
		'name': 'Rifle',
		'damage': 20.0,
		'rof': 120,
		'accuracy': 50.0,
		'clip': 30,
		'knockback': 12.0,
		'slowness': 0.6
	}
};

static func get_weapon(id: int):
	if (id <= 0 || id >= WEAPON_ALL || !weapon_data.has(id)):
		return null;
	return weapon_data[id];

static func calculate_stats(id: int, level: int, enhancement: float):
	var wpn = get_weapon(id);
	if (not wpn):
		return null;
	
	# base stats
	var stats = {
		'damage': wpn.damage,
		'rof': wpn.rof,
		'accuracy': wpn.accuracy,
		'knockback': wpn.knockback,
		'slowness': wpn.slowness
	};
	
	var enhancement_factor = 0.0;
	
	match (wpn.wpn_class):
		CLASS_AR, CLASS_SR:
			enhancement_factor = 0.15;
		CLASS_HG, CLASS_SMG:
			enhancement_factor = 0.25;
		CLASS_SG:
			enhancement_factor = 0.4;
		_:
			enhancement_factor = 0.0;
	
	for i in stats:
		var base_stats = stats[i];
		
		# level scaling
		stats[i] = (base_stats * 0.1) + (base_stats * 0.9 * (level / 100.0));
		
		# enhancement
		stats[i] += base_stats * enhancement_factor;
	
	return stats;

static func check_weapon() -> void:
	var needed_vars = [
		'wpn_class',
		'alias',
		'name',
		'damage',
		'rof',
		'accuracy',
		'clip',
		'knockback',
		'slowness'
	];
	
	for i in range(1, WEAPON_ALL):
		if (!weapon_data.has(i)):
			print("Weapon data for ID ", i, " doesn't exist.");
			continue;
		
		for j in needed_vars:
			if (!weapon_data[i].has(j)):
				print("Weapon ID ", i, " var ", j, " doesn't exist.");
