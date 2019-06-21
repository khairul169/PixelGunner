extends Node

# defs
const TARGETING_RADIUS = 8.0;

# scenes
onready var DamageIndicator = load('res://scenes/ui/hud/damage_indicator.tscn');

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
var armor_pen = 0;

func _ready() -> void:
	# init module
	player.connect("dying", self, "_player_reset");
	
	# initialize attack system
	call_deferred("_initialize");

func _input(event: InputEvent) -> void:
	if (Input.is_key_pressed(KEY_SPACE)):
		start_attack();
	
	if (Input.is_key_pressed(KEY_R)):
		reload();

func _initialize() -> void:
	# targeting
	_create_targeting();
	
	# user button
	player.ui.button_attack.connect("pressed", self, "start_attack");
	player.ui.button_reload.connect("pressed", self, "reload");

func reset() -> void:
	# set default variable value
	damage = 0.0;
	delay = 1.0;
	attack_range = 0.0;
	accuracy = 0.0;
	max_clip = 0;
	wpn_clip = -1;
	reload_time = 0.0;
	attack_type = AttackType.NEAR;
	slowness = 0.0;
	knockback = 0.0;
	armor_pen = 0;
	
	# cancel reload
	if (state == State.RELOADING):
		_reload_canceled();
	
	# update ui
	_update_interface();
	
	# disable targeting
	if (target):
		target = null;
		player.stop();
	
	# reset state
	state = State.IDLE;
	next_think = 0.1;

func _player_reset() -> void:
	# reset vars
	next_think = 0.0;
	target = null;
	reset();

func _create_targeting() -> void:
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
	
	if (player.is_moving):
		if (target):
			# disable targeting
			player.stop();
			target = null;
		
		# set state
		if (state != State.RELOADING):
			state = State.MOVING;
	else:
		if (state == State.MOVING):
			state = State.IDLE;
	
	if (next_think > 0.0):
		return;
	
	if (state == State.RELOADING):
		_reload_finished();
		state = State.IDLE;
		return;
	
	if (state == State.AIMING):
		if (target):
			# set player shooting animation
			player.set_animation(player.PlayerAnims.SHOOT);
			player.stop(0.15);
			player.next_idle = 0.5;
			
			state = State.ATTACKING;
			next_think = delay;
			
			# attack target
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
			next_think = 0.5;
			state = State.MOVING;
		
		else:
			if (state != State.ATTACKING):
				player.stop(0.4);
				player.set_looking_at(target);
				next_think = 0.3;
			else:
				player.stop(0.1);
				next_think = 0.0;
			
			state = State.AIMING;

func set_weapon(weapon: Dictionary) -> void:
	if (player.health <= 0.0):
		return;
	
	var wpn_id = weapon.id if weapon.has('id') else -1;
	var data = Weapon.get_weapon(wpn_id);
	if (not data):
		return;
	
	# reset weapon data
	reset();
	
	# set weapon stats
	var stats = weapon.stats;
	damage = stats.damage;
	delay = clamp(60.0 / stats.rof, 0.2, 6.0);
	accuracy = stats.accuracy;
	max_clip = stats.clip;
	wpn_clip = max_clip;
	knockback = stats.knockback;
	slowness_prob = stats.slowness;
	armor_pen = stats.armorp;
	
	# attack type
	match (data.wpn_class):
		Weapon.CLASS_SR:
			attack_type = AttackType.FAR;
		_:
			attack_type = AttackType.NEAR;
	
	# player animation
	match (data.wpn_class):
		Weapon.CLASS_AR:
			player.anim_offset = player.PlayerAnims.RIFLE_IDLE;
		_:
			player.anim_offset = 0;
	
	# attack range & reload speed
	match (data.wpn_class):
		Weapon.CLASS_HG:
			attack_range = 6.0;
			reload_time = 1.0;
		
		Weapon.CLASS_AR:
			attack_range = 5.0;
			reload_time = 3.0;
		
		_:
			attack_range = 4.0;
			reload_time = 1.0;
	
	# switch weapon mesh
	match (wpn_id):
		Weapon.WEAPON_PISTOL:
			player.find_node('pistol').show();
			player.find_node('rifle').hide();
		
		Weapon.WEAPON_RIFLE:
			player.find_node('pistol').hide();
			player.find_node('rifle').show();
	
	# resupply ammunition
	player.weapon = wpn_id;
	player.m_backpack.resupply_ammo();
	
	# update ui
	call_deferred('_update_interface');

func start_attack() -> void:
	if (next_think > 0.0 || player.health <= 0.0):
		return;
	
	if (wpn_clip <= 0):
		# start reload
		if (state != State.RELOADING):
			reload();
		return;
	
	if (!nearest_enemy.size()):
		return;
	
	if (attack_type == AttackType.RANDOM):
		target = nearest_enemy[randi() % nearest_enemy.size()];
		return;
	
	var res = {};
	for i in nearest_enemy:
		if (check_enemy(i, res)):
			continue;
	
	if (res.has('enemy')):
		if (!target):
			# disable movement for a while
			player.stop(0.2);
		
		# set target
		target = res.enemy;
		state = State.IDLE;
		
		# look at target
		player.set_looking_at(target);
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

func attack(object: Spatial) -> void:
	if (player.health <= 0.0 || !object.is_in_group('damageable')):
		return;
	
	if (wpn_clip <= 0):
		# start reload
		if (state != State.RELOADING):
			reload();
		return;
	
	# look at target
	player.set_looking_at(target);
	
	# reduce clip
	wpn_clip -= 1;
	
	# update ui
	_update_interface();
	
	# check weapon shoot
	var agile = object.agile;
	var miss_chance = agile / (agile + accuracy);
	
	if (randf() < miss_chance):
		# missed shoot
		create_indicator(object, "Miss", Color(1, 1, 1));
		return;
	
	var dmg = damage + (rand_range(-0.2, 0.2) * damage);
	var damage_given = object.give_damage(dmg, player, armor_pen);
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
	
	if (player.m_backpack.get_item_amount(Items.ITEM_AMMUNITION) <= 0):
		return;
	
	# start reload
	state = State.RELOADING;
	next_think = reload_time;
	player.stop();
	_update_interface();

func _reload_canceled() -> void:
	# update ui
	_update_interface();

func _reload_finished() -> void:
	if (state != State.RELOADING):
		return;
	
	if (player.m_backpack.get_item_amount(Items.ITEM_AMMUNITION) <= 0):
		return;
	
	# replenish weapon clip
	wpn_clip = max_clip;
	next_think = 0.1;
	player.m_backpack.remove_item(Items.ITEM_AMMUNITION, 1);
	
	# update ui
	_update_interface();

func _update_interface() -> void:
	if (state == State.RELOADING):
		# show reloading message
		pass
	
	player.ui.set_reloadbutton_clip(wpn_clip);

func create_indicator(object, text, color = Color(1, 1, 1)) -> Node:
	var indicator = DamageIndicator.instance();
	add_child(indicator);
	indicator.init(player.get_viewport().get_camera(), object.global_transform.origin + Vector3.UP);
	indicator.set_text(text);
	indicator.set_color(color);
	return indicator;
