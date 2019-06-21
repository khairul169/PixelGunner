extends Spatial

# editor configs
export (Entities.Monster) var monster_name;
export (float) var radius = 10.0;
export (int) var monster_count = 1;
export (int) var monster_level = 1;

func _ready() -> void:
	var monster_data = Entities.get_monster_data(monster_name);
	if (!visible || !monster_data || !monster_data.has('alias')):
		return;
	
	# load monster scene
	var scene_path = 'res://scenes/monster/' + monster_data.alias + '.tscn';
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
	var m = clamp(monster_level / 100.0, 0.0, 1.0);
	
	# set monster stats
	npc.health_max = lerp(npc.health_max * 0.1, npc.health_max * 0.9, m); 
	npc.accuracy = lerp(npc.accuracy * 0.2, npc.accuracy * 0.8, m); 
	npc.armor = lerp(npc.armor * 0.4, npc.armor * 0.6, m); 
	npc.agile = lerp(0.0, npc.agile, m);
	npc.attack_damage = lerp(npc.attack_damage * 0.1, npc.attack_damage * 0.9, m); 
	npc.attack_delay = lerp(npc.attack_delay * 0.4, npc.attack_delay * 0.6, 1.0 - m);  
