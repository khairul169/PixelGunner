extends Spatial

# refs
onready var camera = $camera;
onready var animsplayer = $player.find_node('AnimationPlayer');

# vars
var camera_transform = Transform();

func _ready() -> void:
	GameData.connect("data_updated", self, "_data_updated");
	
	var weapon = GameState.player.weapon;
	set_weapon(weapon.id if weapon && weapon.has('id') else -1);
	
	camera_transform = camera.transform;
	animsplayer.get_animation('idle').loop = true;
	animsplayer.get_animation('idle_rifle').loop = true;

func _data_updated() -> void:
	var wpn_data = GameData.get_weapon_data(-1);
	set_weapon(wpn_data.id);

func set_weapon(id: int) -> void:
	var mesh_name;
	var anims = 'idle_alt';
	var mesh_list = [
		'pistol',
		'rifle'
	];
	
	if (id < 0):
		mesh_name = null;
		animsplayer.play('idle_alt', 0.1);
	
	if (id == Weapon.WEAPON_PISTOL):
		mesh_name = 'pistol';
		anims = 'idle';
	
	if (id == Weapon.WEAPON_RIFLE):
		mesh_name = 'rifle';
		anims = 'idle_rifle';
	
	for i in $player/Armature/Skeleton.get_children():
		if (!i.name in mesh_list):
			continue;
		
		if (i.name == mesh_name):
			i.show();
		else:
			i.hide();
	
	animsplayer.play(anims, 0.1);

func _process(delta: float) -> void:
	camera.transform = camera.transform.interpolate_with(camera_transform, 8.0 * delta);
