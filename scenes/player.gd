extends KinematicBody

# player class
class_name Player

# reference
onready var m_attack = $attack;
onready var camera = get_parent().get_node('camera');
onready var animplayer: AnimationPlayer = $body/player/AnimationPlayer;

# signals
signal health_changed();

# animation list
enum PlayerAnims {
	IDLE = 0,
	RUN,
	SHOOT,
	DYING,
	
	# Unarmed
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

var next_think = 0.0;
var is_moving = false;
var animation = 'idle';
var anim_speed = 1.0;
var next_idle = 0.0;
var anim_offset = 0;

var health_max = 100.0;
var health = 0.0;
var armor = 0.0;
var move_speed = 3.0;

func _ready() -> void:
	add_to_group('damageable');
	
	# init floating bar
	$player_bar.always_visible = true;
	$player_bar.init("Eclaire", health_max);
	
	# set initial health
	set_health(health_max);

func set_health(new_health: float) -> void:
	health = clamp(new_health, 0.0, health_max);
	emit_signal("health_changed", health);

func give_damage(damage: float, source = null) -> void:
	if (health <= 0.0):
		return;
	
	# armor penetration
	damage = max(1.0, damage - armor);
	
	# reduce health
	set_health(health - damage);
	
	if (has_method('_damaged')):
		self.call('_damaged', damage, source);
	
	if (health <= 0.0 && has_method('_died')):
		self.call('_died');

func _damaged(damage, attacker) -> void:
	$attack.create_indicator(self, str(int(damage)), Color(1, 0.2, 0.2));

func _died() -> void:
	set_animation(PlayerAnims.DYING, 0.1);

func _physics_process(delta: float) -> void:
	if (health <= 0.0):
		return;
	
	var aim := Basis();
	var dir := Vector3.ZERO;
	var navigation_dir;
	
	# navigation
	if (navigate_to is Vector3):
		var pos = global_transform.origin;
		var d = pos.distance_to(navigate_to);
		
		if (d <= delta * move_speed):
			navigate_to = null;
		else:
			navigation_dir = navigate_to - pos;
			navigation_dir.y = 0.0;
			navigation_dir = navigation_dir.normalized();
	
	# get aim basis from camera
	aim = camera.camera_dir;
	
	if (Input.is_key_pressed(KEY_W)):
		dir -= aim.z;
	if (Input.is_key_pressed(KEY_S)):
		dir += aim.z;
	if (Input.is_key_pressed(KEY_A)):
		dir -= aim.x;
	if (Input.is_key_pressed(KEY_D)):
		dir += aim.x;
	
	# normalize dir
	dir.y = 0.0;
	dir = dir.normalized();
	
	# player is moving
	is_moving = (next_think <= 0.0 && dir.length() > 0.1);
	
	if (navigation_dir):
		if (is_moving):
			navigation_dir = null;
		else:
			dir = navigation_dir;
	
	# apply gravity
	var gv = velocity.y - (19.6 * delta);
	
	# set velocity
	if (next_think > 0.0):
		dir = Vector3();
	
	velocity = velocity.linear_interpolate(dir * move_speed, 10 * delta);
	velocity.y = gv;
	
	# move player
	velocity = move_and_slide(velocity, Vector3.UP, true);
	
	if (velocity.length() > 0.5):
		animation = anims[anim_offset + PlayerAnims.RUN];
		anim_speed = clamp(move_speed / 3.0, 0.1, 2.0);
		next_idle = 0.0;
	else:
		animation = anims[anim_offset + PlayerAnims.IDLE];
		anim_speed = 1.0;
	
	if (dir.length() > 0.1):
		body_dir = dir;

func _process(delta: float) -> void:
	if (health <= 0.0):
		return;
	
	if (next_think > 0.0):
		next_think -= delta;
	
	if (next_idle > 0.0):
		next_idle -= delta;
	
	# body rotation
	var body: Spatial = $body;
	var q1 = Quat(body.transform.basis);
	var q2 = Quat(body.transform.looking_at(body_dir, Vector3.UP).basis);
	body.transform.basis = Basis(q1.slerp(q2, 10 * delta));
	
	if (animplayer.current_animation != animation && next_idle <= 0.0):
		animplayer.get_animation(animation).loop = true;
		animplayer.play(animation, 0.1, anim_speed);
		next_idle = 0.1;

func move_to(position, delay = 0.0) -> void:
	navigate_to = position;
	next_think = delay;

func set_animation(id: int, blend_time: float = 0.0) -> void:
	if (id < 0 || id >= anims.size()):
		return;
	
	var animation_name = anims[id];
	if (anim_offset + id < anims.size()):
		animation_name = anims[anim_offset + id];
	
	animplayer.play(animation_name, blend_time);
	animplayer.seek(0.0);
