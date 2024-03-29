extends KinematicBody

# player class
class_name Player

# reference
onready var camera = get_parent().get_node('camera');
onready var body: Spatial = $body;
onready var animplayer: AnimationPlayer = $body/player/AnimationPlayer;
onready var ui = get_tree().get_root().get_node("main/ui");

onready var m_attack = $attack;
onready var m_backpack = $backpack;
onready var m_interact = $interact;

# signals
signal health_changed();
signal spawn();
signal dying();

# animation list
enum PlayerAnims {
	IDLE = 0,
	RUN,
	SHOOT,
	DYING,
	
	# Unarmed
	UNARMED_IDLE,
	UNARMED_RUN,
	
	# Weapon: Rifle
	RIFLE_IDLE,
	RIFLE_RUN,
	RIFLE_SHOOT
};

var anims = [
	'idle',
	'run',
	'shoot',
	'dying',
	
	# Unarmed
	'idle_alt',
	'run_alt',
	
	# Weapon: Rifle
	'idle_rifle',
	'run_rifle',
	'shoot_rifle'
];

# vars
var velocity := Vector3.ZERO;
var body_dir := Vector3.FORWARD;
var navigate_to;
var control_enabled := true;

var next_think = 0.0;
var is_moving = false;
var animation;
var anim_speed = 1.0;
var next_idle = 0.0;
var anim_offset = 0;
var weapon;

var move_speed = 3.0;
var health_max = 100.0;
var health = 0.0;
var armor = 0.0;
var agile = 10.0;

func _ready() -> void:
	# set group
	add_to_group("damageable");
	
	# spawn player
	spawn(Vector3.ZERO + Vector3(0, 1, 0));

func _input(event: InputEvent) -> void:
	if (Input.is_key_pressed(KEY_ESCAPE)):
		GameState.goto_mainmenu();

func set_health(new_health: float) -> void:
	# set player health
	health = clamp(new_health, 0.0, health_max);
	emit_signal("health_changed", health);

func give_damage(damage: float, source = null, armor_pen = 0.0) -> void:
	if (health <= 0.0):
		return;
	
	# missed shoot
	if (damage <= 0.0):
		m_attack.create_indicator(self, "Miss", Color(1, 1, 1));
		return;
	
	# armor penetration
	if (armor_pen < armor):
		damage = max(1.0, damage - armor);
	
	# reduce health
	set_health(health - damage);
	_damaged(damage, source);
	
	if (health <= 0.0):
		_dying();
		emit_signal("dying");

func spawn(position: Vector3) -> void:
	# set player health
	set_health(health_max);
	
	# set position
	global_transform.origin = position;
	
	# emit spawn signal
	_on_spawn();
	emit_signal("spawn");

func _on_spawn() -> void:
	# reset vars
	camera.fov = 60.0;
	body_dir = Vector3.FORWARD;
	navigate_to = null;
	
	next_think = 0.5;
	is_moving = false;
	animation = null;
	anim_speed = 1.0;
	next_idle = 0.0;
	anim_offset = 0;
	weapon = null;
	
	m_attack.set_weapon(GameState.player.weapon);
	m_backpack.resupply_ammo();

func _damaged(damage, attacker) -> void:
	if (damage <= 0.0):
		return;
	
	# damage indicator
	m_attack.create_indicator(self, str(int(damage)), Color(1, 0.2, 0.2));

func _dying() -> void:
	set_animation(PlayerAnims.DYING, 0.1);
	camera.fov = 40.0;
	next_think = 3.0;

func _physics_process(delta: float) -> void:
	if (health <= 0.0):
		if (next_think <= 0.0):
			spawn(Vector3(0, 1, 0));
		return;
	
	var dir := Vector3.ZERO;
	var navigation_dir;
	
	if (next_think <= 0.0 && control_enabled):
		# key movement
		if (Input.is_key_pressed(KEY_W)):
			dir -= camera.camera_dir.z;
		if (Input.is_key_pressed(KEY_S)):
			dir += camera.camera_dir.z;
		if (Input.is_key_pressed(KEY_A)):
			dir -= camera.camera_dir.x;
		if (Input.is_key_pressed(KEY_D)):
			dir += camera.camera_dir.x;
		
		# touch movement
		if (ui.controller):
			var input_dir: Vector3 = ui.controller.dir;
			if (input_dir.length() > 0.1):
				dir = camera.camera_dir.xform(input_dir);
		
		# navigation
		if (navigate_to && typeof(navigate_to) == TYPE_VECTOR3):
			var pos = global_transform.origin;
			var d = pos.distance_to(navigate_to);
			
			if (d > delta * move_speed):
				navigation_dir = navigate_to - pos;
				navigation_dir.y = 0.0;
				navigation_dir = navigation_dir.normalized();
			else:
				navigate_to = null;
		
		# normalize dir
		dir.y = 0.0;
		dir = dir.normalized();
	
	# player movement state
	is_moving = (dir.length() > 0.1);
	
	# set body direction
	if (is_moving):
		body_dir = dir;
	
	# set player moving to navigation point if available
	if (navigation_dir && typeof(navigation_dir) == TYPE_VECTOR3):
		if (is_moving):
			navigation_dir = null;
		else:
			dir = navigation_dir;
	
	# apply gravity
	var gv = velocity.y - (19.6 * delta);
	
	# set velocity
	velocity = velocity.linear_interpolate(dir * move_speed, 10 * delta);
	velocity.y = gv;
	
	# move player
	velocity = move_and_slide(velocity, Vector3.UP, true);

func _process(delta: float) -> void:
	if (next_think > 0.0):
		next_think -= delta;
	
	if (health <= 0.0):
		return;
	
	if (next_idle > 0.0):
		next_idle -= delta;
	
	# animation
	var hvel = Vector3(velocity.x, 0, velocity.z);
	if (hvel.length() > 0.5):
		animation = anims[anim_offset + PlayerAnims.RUN];
		anim_speed = clamp(move_speed / 3.0, 0.1, 2.0);
		next_idle = 0.0;
	else:
		animation = anims[anim_offset + PlayerAnims.IDLE];
		anim_speed = 1.0;
	
	if (next_idle <= 0.0 && animplayer.current_animation != animation):
		animplayer.get_animation(animation).loop = true;
		animplayer.play(animation, 0.1, anim_speed);
		next_idle = 0.1;
	
	# body rotation
	var q1 = Quat(body.transform.basis);
	var q2 = Quat(body.transform.looking_at(body_dir, Vector3.UP).basis);
	body.transform.basis = Basis(q1.slerp(q2, 10 * delta));

func move_to(position: Vector3) -> void:
	navigate_to = position;
	next_think = 0.0;

func stop(next_move: float = 0.0) -> void:
	navigate_to = null;
	next_think = next_move;

func set_looking_at(object: Spatial) -> void:
	body_dir = object.global_transform.origin - global_transform.origin;
	body_dir.y = 0.0;
	body_dir = body_dir.normalized();

func set_animation(id: int, blend_time: float = 0.0) -> void:
	if (id < 0 || id >= anims.size()):
		return;
	
	var animation_name = anims[id];
	if (anim_offset + id < anims.size()):
		animation_name = anims[anim_offset + id];
	
	animplayer.play(animation_name, blend_time);
	animplayer.seek(0.0);

func give_item(item_id: int, amount: int = 1) -> void:
	m_backpack.add_item(item_id, amount);
