extends Spatial

enum MonsterList {
	CROG = 0,
	RANGED
};

const MonsterAlias = [
	'crog',
	'ranged'
];

export (MonsterList) var monster_name = MonsterList.CROG;
export (float) var radius = 10.0;
export (int) var monster_count = 1;
export (int) var monster_level = 1;

func _ready() -> void:
	if (!visible || monster_name < 0 || monster_name >= MonsterAlias.size()):
		return;
	
	# load monster scene
	var scene_path = 'res://scenes/monster/' + MonsterAlias[monster_name] + '.tscn';
	var scene = load(scene_path);
	
	# scene isn't exists
	if (!scene):
		return;
	
	for i in range(0, monster_count):
		# instace scene
		var npc = scene.instance();
		var ang = randf() * 2 * PI;
		var rad = max(1.0, randf() * radius);
		var pos = Vector3(sin(ang) * rad, 1.0, cos(ang) * rad);
		npc.transform.origin = pos;
		set_monster_stats(npc);
		
		# add to tree
		add_child(npc);

func set_monster_stats(npc) -> void:
	# stats modifier
	var modifier = rand_range(0.08, 0.15) * max(monster_level - 1, 0);
	
	# set monster stats
	npc.health_max += npc.health_max * modifier;
	npc.attack_damage += npc.attack_damage * modifier;
	npc.attack_delay -= min(npc.attack_delay * modifier, 0.2);
	npc.accuracy += npc.accuracy * modifier;
	npc.armor += npc.armor * modifier;
	npc.agile += npc.agile * modifier;
	
	# set monster name
	npc.monster_name = str('Lv', monster_level, ' ', npc.monster_name);
