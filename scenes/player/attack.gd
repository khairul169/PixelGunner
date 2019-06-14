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
	ATTACKING
};

# attack type
enum AttackType {
	NEAR = 0,
	FAR,
	BOSS,
	RANDOM
};

# vars
var nearest_enemy := [];
var target;
var next_think = 0.0;
var state = State.IDLE;

var damage = 20.0;
var delay = 0.6;
var attack_range = 6.0;
var accuracy = 15.0;
var attack_type = AttackType.NEAR;
var slowness_prob = 0.6;
var slowness_time = 1.0;
var knock_prob = 0.4;
var knock_size = 10.0;

func _ready() -> void:
	# createa area targeting node
	call_deferred('create_targeting');
	
	player.anim_offset = player.PlayerAnims.RIFLE_IDLE;

func _input(event: InputEvent) -> void:
	if (Input.is_key_pressed(KEY_SPACE)):
		start_attack();

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
	
	# reset move
	if (target && player.is_moving):
		player.move_to(null);
		target = null;
		state = State.IDLE;
	
	if (next_think > 0.0):
		return;
	
	if (state == State.AIMING):
		if (target):
			# shoot target
			player.set_animation(player.PlayerAnims.SHOOT);
			player.next_idle = 0.5;
			attack(target);
			state = State.ATTACKING;
			next_think = delay;
			
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
	if (player.health <= 0.0 || !object.is_in_group('damageable')):
		return;
	
	# set looking at target
	set_look_at(target);
	
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
		object.set_slow(slowness_time);
	
	if (randf() <= knock_prob && object.has_method('set_impulse')):
		# knock back object
		var impulse = object.global_transform.origin - player.global_transform.origin;
		impulse.y = 0.0;
		impulse = impulse.normalized() * (knock_size + (knock_size * rand_range(-0.15, 0.15)));
		object.set_impulse(impulse);

func create_indicator(object, text, color = Color(1, 1, 1)) -> Node:
	var indicator = DamageIndicator.instance();
	add_child(indicator);
	indicator.init(player.get_viewport().get_camera(), object.global_transform.origin + Vector3.UP);
	indicator.set_text(text);
	indicator.set_color(color);
	return indicator;
