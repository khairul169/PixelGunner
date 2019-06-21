extends Node

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

enum {
	EQ_SLOT_STOCK = 0,
	EQ_SLOT_MAGAZINE,
	EQ_SLOT_SIGHT,
	EQ_SLOT_GRIP,
	EQ_SLOT_SIDE
};

const weapon_data = {
	
	# pistol
	WEAPON_PISTOL: {
		'wpn_class': CLASS_HG,
		'alias': 'pistol',
		'name': 'Pistol',
		'stats': {
			'damage': 40.0,
			'rof': 120,
			'accuracy': 20.0,
			'clip': 12,
			'armorp': 0,
			'knockback': 10.0,
			'slowness': 0.2
		}
	},
	
	# rifle
	WEAPON_RIFLE: {
		'wpn_class': CLASS_AR,
		'alias': 'rifle',
		'name': 'Rifle',
		'stats': {
			'damage': 60.0,
			'rof': 280,
			'accuracy': 50.0,
			'clip': 30,
			'armorp': 95,
			'knockback': 12.0,
			'slowness': 0.6
		}
	}
};

static func get_weapon(id: int):
	if (id > 0 && weapon_data.has(id)):
		return weapon_data[id];

static func get_stats(data: Dictionary):
	# format dict: id, enhancement, level, upgrade, equip
	var wpn = get_weapon(data.id if data.has('id') else -1);
	if (not wpn):
		return null;
	
	# weapon stats
	var stats = {};
	var ignored_stats = ['clip', 'armorp'];
	
	for i in wpn.stats:
		var base_stats = wpn.stats[i];
		
		if (i == 'clip'):
			stats[i] = base_stats;
			continue;
		
		# level scaling
		stats[i] = (base_stats * 0.2) + (base_stats * 0.6 * (data.level / 100.0));
		
		# enhancement
		stats[i] += base_stats * 0.2 * clamp(data.enhancement, 0.0, 1.0);
		
		# weapon upgrade
		stats[i] += stats[i] * 0.1 * clamp(data.upgrade / 1.0, 0.0, 2.0);
	
	# equipment
	if (data.has('equip')):
		var equipment = data.equip;
		for i in equipment:
			pass
	
	# clamp value
	stats['rof'] = clamp(stats['rof'], 0.0, 300.0);
	stats['slowness'] = clamp(stats['slowness'], 0.0, 1.0);
	
	return stats;

static func check_weapon() -> void:
	var needed_vars = [
		'wpn_class',
		'alias',
		'name',
		'stats'
	];
	
	for i in range(1, WEAPON_ALL):
		if (!weapon_data.has(i)):
			print("Weapon data for ID ", i, " doesn't exist.");
			continue;
		
		for j in needed_vars:
			if (!weapon_data[i].has(j)):
				print("Weapon ID ", i, " var ", j, " doesn't exist.");
