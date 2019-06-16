extends Node

# defs
const TARGETING_RADIUS = 8.0;

# scenes
onready var DamageIndicator = load('res://scenes/ui/indicator_damage.tscn');

# reference
onready var player: Player = get_parent();

# state
enum State {
	IDLE = 0,
	MOVING,
	AIMING,
	ATTACKING,
	RELOADING
};

# attack type
enum AttackType {
	NEAR = 0,
	FAR,
	BOSS,
	RANDOM
};

# vars
var next_think = 0.0;
var state = State.IDLE;
var nearest_enemy := [];
var target;
var wpn_clip = 0;

var damage = 20.0;
var delay = 0.4;
var attack_range = 6.0;
var accuracy = 10.0;
var max_clip = 0;
var attack_type = AttackType.NEAR;
var reload_time = 0.0;
var slowness_prob = 0.6;
var slowness = 0.5;
var knock_prob = 0.4;
var knockback = 10.0;

func _ready() -> void:
	# init module
	player.connect("spawn", self, "_player_spawn");
	
	# initialize attack system
	call_deferred("init");

func _input(event: InputEvent) -> void:
	if (Input.is_key_pressed(KEY_SPACE)):
		start_attack();
	
	if (Input.is_key_pressed(KEY_1)):
		set_weapon(PlayerWeapon.WEAPON_PISTOL);
	
	if (Input.is_key_pressed(KEY_2)):
		set_weapon(PlayerWeapon.WEAPON_RIFLE);

func init() -> void:
	# targeting
	create_targeting();
	
	# attack button
	player.ui.button_attack.connect("pressed", self, "start_attack");

func reset_weapon() -> void:
	damage = 0.0;
	delay = 1.0;
	attack_range = 1.0;
	accuracy = 0.0;
	max_clip = 0;
	wpn_clip = 0;
	reload_time = 0.0;
	attack_type = AttackType.NEAR;
	slowness = 0.0;
	knockback = 0.0;

func set_weapon(id: int) -> void:
	if (id <= 0):
		reset_weapon();
		return;
	
	var weapon_data = PlayerWeapon.get_weapon(id);
	if (!weapon_data):
		return;
	
	print('set weapon ', id);
	
	# set weapon data
	damage = weapon_data.damage;
	delay = 60.0 / weapon_data.rof;
	attack_range = weapon_data.attack_range;
	accuracy = weapon_data.accuracy;
	max_clip = weapon_data.clip;
	wpn_clip = max_clip;
	knockback = weapon_data.knockback;
	slowness = weapon_data.slowness;
	
	# attack type
	match (weapon_data.wpn_class):
		PlayerWeapon.CLASS_SR:
			attack_type = AttackType.FAR;
		_:
			attack_type = AttackType.NEAR;
	
	# player animation
	match (weapon_data.wpn_class):
		PlayerWeapon.CLASS_AR:
			player.anim_offset = player.PlayerAnims.RIFLE_IDLE;
		_:
			player.anim_offset = 0;
	
	# reload speed
	match (weapon_data.wpn_class):
		PlayerWeapon.CLASS_HG:
			reload_time = 1.0;
		PlayerWeapon.CLASS_AR:
			reload_time = 3.0;
		_:
			reload_time = 1.0;
	
	# reload speed
	match (id):
		PlayerWeapon.WEAPON_PISTOL:
			player.find_node('pistol').show();
			player.find_node('rifle').hide();
		
		PlayerWeapon.WEAPON_RIFLE:
			player.find_node('pistol').hide();
			player.find_node('rifle').show();

func _player_spawn() -> void:
	# reset vars
	next_think = 0.0;
	state = State.IDLE;
	target = null;
	reset_weapon();

func create_targeting() -> void:
	# shape reference
	var shape = SphereShape.new();
	shape.radius = TARGETING_RADIUS;
	
	# collision shape
	var col = CollisionShape.new();
	col.shape = shape;
	
	# create area
	var area = Area.new();
	area.add_child(col);
	player.add_child(area);
	
	# connect signals
	area.connect("body_entered", self, "_object_enter");
	area.connect("body_exited", self, "_object_exit");

func _object_enter(object: Node) -> void:
	if (object == player):
		return;
	
	if (object.is_in_group('damageable') && !object in nearest_enemy):
		nearest_enemy.append(object);

func _object_exit(object: Node) -> void:
	if (object in nearest_enemy):
		nearest_enemy.erase(object);

func _process(delta: float) -> void:
	if (player.health <= 0.0):
		return;
	
	if (next_think > 0.0):
		next_think -= delta;

func _physics_process(delta: float) -> void:
	if (player.health <= 0.0):
		return;
	
	# player moving
	if (target && player.is_moving):
		# reset state
		if (state != State.RELOADING):
			state = State.IDLE;
		
		# enable movement & reset target
		player.move_to(null);
		target = null;
	
	if (next_think > 0.0):
		return;
	
	if (wpn_clip <= 0 && state != State.RELOADING):
		# start reload
		reload();
		return;
	
	if (state == State.RELOADING):
		wpn_clip = max_clip;
		next_think = 0.5;
		state = State.IDLE;
		return;
	
	if (state == State.AIMING):
		if (target):
			# shoot target
			player.set_animation(player.PlayerAnims.SHOOT);
			player.next_idle = 0.5;
			state = State.ATTACKING;
			next_think = delay;
			attack(target);
			
			# reset target if randomized attack
			if (attack_type == AttackType.RANDOM):
				target = null;
				start_attack();
		else:
			state = State.IDLE;
			next_think = 0.5;
		return;
	
	if (target):
		if (target.health <= 0.0):
			target = null;
			state = State.IDLE;
			
			if (attack_type == AttackType.RANDOM):
				start_attack();
			return;
		
		var distance = player.global_transform.origin.distance_to(target.global_transform.origin);
		if (distance > attack_range && attack_type != AttackType.RANDOM):
			player.move_to(target.global_transform.origin);
			next_think = 0.2;
			state = State.MOVING;
		else:
			if (state != State.ATTACKING):
				player.move_to(null, 0.5);
				next_think = 0.4;
				set_look_at(target);
			else:
				player.move_to(null, 0.1);
				next_think = 0.0;
			
			state = State.AIMING;

func start_attack() -> void:
	if (player.health <= 0.0 || !nearest_enemy.size()):
		return;
	
	if (attack_type == AttackType.RANDOM):
		target = nearest_enemy[randi() % nearest_enemy.size()];
		return;
	
	var res = {};
	for i in nearest_enemy:
		if (check_enemy(i, res)):
			continue;
	
	if (res.has('enemy')):
		# set target
		target = res.enemy;
	else:
		target = null;

func check_enemy(enemy: Spatial, res: Dictionary) -> bool:
	if (!enemy.is_in_group('damageable')):
		return true;
	
	# health check
	if (enemy.health <= 0.0):
		return true;
	
	var last_distance = -1.0;
	if (res.has('distance')):
		last_distance = res.distance;
	
	var enemy_pos = enemy.global_transform.origin;
	var distance = player.global_transform.origin.distance_to(enemy_pos);
	
	# distance check
	if (attack_type == AttackType.NEAR):
		if (last_distance >= 0.0 && !(distance <= last_distance)):
			return true;
	
	if (attack_type == AttackType.FAR):
		if (last_distance >= 0.0 && !(distance > last_distance)):
			return true;
	
	# set result
	res.enemy = enemy;
	res.distance = distance;
	return false;

func set_look_at(object: Spatial) -> void:
	player.body_dir = object.global_transform.origin - player.global_transform.origin;
	player.body_dir.y = 0.0;
	player.body_dir = player.body_dir.normalized();

func attack(object: Spatial) -> void:
	if (player.health <= 0.0 || !object.is_in_group('damageable') || wpn_clip <= 0):
		return;
	
	# set looking at target
	set_look_at(target);
	
	# reduce clip
	wpn_clip -= 1;
	
	# check weapon shoot
	var agile = object.agile;
	var miss_chance = agile / (agile + accuracy);
	
	if (randf() < miss_chance):
		# missed shoot
		create_indicator(object, "Miss", Color(1, 1, 1));
		return;
	
	var dmg = damage + (rand_range(-0.2, 0.2) * damage);
	var damage_given = object.give_damage(dmg, player);
	create_indicator(object, str(int(damage_given)), Color(1, 0.2, 0.2));
	
	if (randf() <= slowness_prob && object.has_method('set_slow')):
		# give slowness
		object.set_slow(1.0, slowness);
	
	if (randf() <= knock_prob && object.has_method('set_impulse')):
		# knock back object
		var impulse = object.global_transform.origin - player.global_transform.origin;
		impulse.y = 0.0;
		impulse = impulse.normalized() * (knockback + (knockback * rand_range(-0.15, 0.15)));
		object.set_impulse(impulse);

func reload() -> void:
	if (wpn_clip >= max_clip || state == State.RELOADING):
		return;
	
	# start reload
	state = State.RELOADING;
	next_think = reload_time;

func create_indicator(object, text, color = Color(1, 1, 1)) -> Node:
	var indicator = DamageIndicator.instance();
	add_child(indicator);
	indicator.init(player.get_viewport().get_camera(), object.global_transform.origin + Vector3.UP);
	indicator.set_text(text);
	indicator.set_color(color);
	return indicator;
