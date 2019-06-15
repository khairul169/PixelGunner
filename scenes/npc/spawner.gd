extends Spatial

enum NPCList {
	CROG = 0,
	RANGED
};

const NPCAlias = [
	'crog',
	'ranged'
];

export (NPCList) var npc_name = NPCList.CROG;
export (float) var radius = 10.0;
export (int) var npc_count = 1;
export (int) var npc_level = 1;

func _ready() -> void:
	if (npc_name < 0 || npc_name >= NPCAlias.size()):
		return;
	
	var scene_path = 'res://scenes/npc/' + NPCAlias[npc_name] + '.tscn';
	var scene = load(scene_path);
	
	if (!scene):
		return;
	
	for i in range(0, npc_count):
		var npc = scene.instance();
		var ang = randf() * 2 * PI;
		var rad = max(1.0, randf() * radius);
		var pos = Vector3(sin(ang) * rad, 1.0, cos(ang) * rad);
		npc.transform.origin = pos;
		npc.level = npc_level;
		set_npc_stats(npc);
		add_child(npc);

func set_npc_stats(npc) -> void:
	var offs = rand_range(0.08, 0.15) * max(npc_level - 1, 0);
	npc.health_max += npc.health_max * offs;
	npc.attack_damage += npc.attack_damage * offs;
	npc.attack_delay -= npc.attack_delay * min(offs, 0.2);
	npc.accuracy += npc.accuracy * offs;
	npc.armor += npc.armor * offs;
	npc.agile += npc.agile * offs;
