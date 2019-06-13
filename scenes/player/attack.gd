extends Node

const TARGETING_RADIUS = 8.0;

onready var player: Player = get_parent();

enum State {
	IDLE = 0,
	MOVING,
	AIMING,
	ATTACKING
};

# vars
var nearest_enemy := [];
var target;
var next_think = 0.0;
var state = State.IDLE;

var damage = 20.0;
var delay = 0.4;
var attack_range = 5.0;
var accuracy = 10.0;
var slowness_prob = 0.4;
var slowness_time = 1.0;
var knock_prob = 0.4;
var knock_size = 10.0;

onready var DamageIndicator = load('res://scenes/ui/indicator_damage.tscn');

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
		else:
			state = State.IDLE;
			next_think = 0.5;
		return;
	
	if (target):
		if (target.health <= 0.0):
			target = null;
			return;
		
		var distance = player.global_transform.origin.distance_to(target.global_transform.origin);
		if (distance > attack_range):
			player.move_to(target.global_transform.origin);
			next_think = 0.2;
			state = State.MOVING;
		else:
			if (state != State.ATTACKING):
				player.move_to(null, 0.5);
				next_think = 0.4;
				look_at(target);
			else:
				player.move_to(null, 0.1);
				next_think = 0.0;
			
			state = State.AIMING;

func start_attack() -> void:
	if (player.health <= 0.0):
		return;
	
	var enemy;
	var last_distance = -1;
	for i in nearest_enemy:
		var distance = player.global_transform.origin.distance_to(i.global_transform.origin);
		if (last_distance >= 0.0 && distance >= last_distance):
			continue;
		
		if (i.health <= 0.0):
			continue;
		
		enemy = i;
		last_distance = distance;
	
	if (enemy && enemy is Spatial):
		# set target
		target = enemy;
	else:
		target = null;

func look_at(object: Spatial) -> void:
	var target_pos = object.global_transform.origin;
	var look_dir = object.global_transform.origin - player.global_transform.origin;
	look_dir.y = 0.0;
	look_dir = look_dir.normalized();
	player.body_dir = look_dir;

func attack(object: Spatial) -> void:
	if (player.health <= 0.0 || !object.is_in_group('damageable')):
		return;
	
	look_at(target);
	
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
