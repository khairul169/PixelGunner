extends KinematicBody
class_name Monster

# scenes
onready var FloatingBar = load('res://scenes/ui/floating_bar.tscn');

# reference
onready var body = $body;
onready var anims = find_node('AnimationPlayer');

# signals
signal health_changed(health_num);
signal spawn();
signal dying();

# defs
enum DebuffType {
	NONE = 0,
	SLOWNESS,
	STUN,
	ATTACK_DAMAGE,
	ATTACK_SPEED,
	ARMOR
};

# vars
var velocity := Vector3.ZERO;
var next_think = 0.0;
var target = [];
var move_to;
var body_dir := Vector3.FORWARD;
var impulse := Vector3.ZERO;
var next_idle = 0.0;
var debuff_list = [];

export(float) var health_max = 100.0;
var health = 0.0;

export(String) var monster_name = "Monster";
export(float) var move_speed = 1.0;
export(float) var attack_damage = 1.0;
export(float) var attack_delay = 1.0;
export(float) var attack_range = 1.0;
export(float) var accuracy = 0.0;
export(float) var armor = 0.0;
export(float) var agile = 0.0;

func _ready() -> void:
	add_to_group('damageable');
	
	$detection.connect("body_entered", self, "_obj_enter");
	$detection.connect("body_exited", self, "_obj_exit");
	
	# create floating bar
	var uibar = FloatingBar.instance();
	add_child(uibar);
	uibar.healthbar_color = Color('#d63d3d');
	uibar.init(monster_name, health_max);
	
	# spawn npc
	spawn(global_transform.origin + Vector3.UP);

func set_health(new_health: float) -> void:
	# set npc health
	health = clamp(new_health, 0.0, health_max);
	emit_signal("health_changed", health);

func give_damage(damage: float, source = null) -> float:
	if (health <= 0.0):
		return 0.0;
	
	# armor penetration
	damage = max(1.0, damage - armor);
	
	# reduce health
	set_health(health - damage);
	
	if (has_method('_damaged')):
		_damaged(damage, source);
	
	if (health <= 0.0 && has_method('_dying')):
		_dying();
		emit_signal("dying");
	
	return damage;

func spawn(position: Vector3) -> void:
	# spawn npc
	set_health(health_max);
	global_transform.origin = position;
	
	# emit spawn signal
	_on_spawn();
	emit_signal("spawn");

func _on_spawn() -> void:
	# reset vars
	velocity = Vector3.ZERO;
	next_think = 0.5;
	move_to = null;
	body_dir = Vector3.FORWARD;
	impulse = Vector3.ZERO;
	debuff_list.clear();
	
	# enable collision shape
	$shape.disabled = false;

func _damaged(damage, source) -> void:
	# chase attacker if target is not defined
	if (target.empty() && source.is_in_group('damageable')):
		target.append(source);

func _dying() -> void:
	# play dying animation
	set_animation('dying');
	next_idle = 0.5;
	
	# disable collision shape
	$shape.disabled = true;
	
	# corpse removal delay
	next_think = 5.0;

func _obj_enter(obj) -> void:
	if (obj is Player && !obj in target):
		target.append(obj);

func _obj_exit(obj) -> void:
	if (obj in target):
		target.erase(obj);

func _process(delta: float) -> void:
	if (next_think > 0.0):
		next_think -= delta;
	
	if (next_idle > 0.0):
		next_idle -= delta;
	
	if (health > 0.0 && next_idle <= 0.0 && anims is AnimationPlayer):
		# switch animation
		var animation_name = 'idle';
		var hvel = Vector3(velocity.x, 0, velocity.z);
		if (hvel.length() > 0.5):
			animation_name = 'run';
		
		if (anims.current_animation != animation_name && anims.has_animation(animation_name)):
			anims.get_animation(animation_name).loop = true;
			anims.play(animation_name, 0.1);
		
		next_idle = 0.1;
	
	# body rotation
	if (body_dir && body_dir.length() > 0.1):
		var q1 = Quat(body.transform.basis);
		var q2 = Quat(body.transform.looking_at(body_dir, Vector3.UP).basis);
		body.transform.basis = Basis(q1.slerp(q2, 10 * delta));
	
	# debuff
	for i in debuff_list:
		if (i[1] > 0.0):
			# reduce debuff time
			i[1] -= delta;
		else:
			# remove debuff
			debuff_list.erase(i);

func _physics_process(delta: float) -> void:
	if (health <= 0.0):
		if (next_think <= 0.0):
			# remove corpse
			queue_free();
		return;
	
	if (next_think <= 0.0):
		_think();
	
	var dir := Vector3.ZERO;
	if (move_to):
		dir = move_to - global_transform.origin;
		dir.y = 0.0;
		dir = dir.normalized();
	
	# add gravity
	var gv = velocity.y - (19.6 * delta);
	
	# check for debuff
	var stun = false;
	var slowness = 0.0;
	
	for i in debuff_list:
		var type = i[0];
		
		if (type == DebuffType.STUN):
			stun = true;
			break;
		
		if (type == DebuffType.SLOWNESS):
			if (slowness > 0.0):
				slowness = clamp(min(slowness, i[2]), 0.1, 1.0);
			else:
				slowness = clamp(i[2], 0.1, 1.0);
	
	if (stun):
		dir = Vector3.ZERO;
		velocity = dir;
	
	# slow
	elif (slowness > 0.0):
		velocity = dir * move_speed * slowness;
	
	else:
		velocity = dir * move_speed;
	
	# apply gravity
	velocity.y = gv;
	
	if (impulse.length() > 0.1):
		velocity += impulse;
		impulse = impulse.linear_interpolate(Vector3.ZERO, 10.0 * delta);
	
	# move object
	velocity = move_and_slide(velocity, Vector3.UP);
	
	var hvel = Vector3(dir.x, 0, dir.z);
	if (hvel.length() > 0.1):
		body_dir = hvel;
		next_idle = 0.0;

func _think() -> void:
	if (!target.size()):
		if (move_to):
			move_to = null;
		return;
	
	var enemy;
	for i in target:
		if (i.health <= 0.0):
			continue;
		
		enemy = i;
		break;
	
	if (!enemy):
		move_to = null;
		next_think = 0.5;
		return;
	
	var dist = global_transform.origin.distance_to(enemy.global_transform.origin);
	if (dist > attack_range):
		move_to = enemy.global_transform.origin;
		next_think = 0.5;
	else:
		move_to = null;
		next_think = 0.1;
		attack(enemy);

func attack(object) -> void:
	if (!object || !object is Spatial):
		return;
	
	# set looking at enemy
	set_look_at(object);
	
	# attack animation
	set_animation('shoot');
	next_idle = 0.5;
	
	# attack damage
	var damage = 0.0;
	
	# attack accuracy
	var agile = object.agile;
	var miss_chance = agile / (agile + accuracy);
	
	# hit successful
	if (accuracy <= 0.0 || randf() >= miss_chance):
		damage = attack_damage + (rand_range(-0.15, 0.15) * attack_damage);
	
	if (object.has_method('give_damage')):
		object.give_damage(damage, self);
	
	# delay attack
	next_think = attack_delay;

func set_look_at(object: Spatial) -> void:
	body_dir = object.global_transform.origin - global_transform.origin;
	body_dir.y = 0.0;
	body_dir = body_dir.normalized();

func set_stun(time = 0.0) -> void:
	for i in debuff_list:
		if (i[0] == DebuffType.STUN):
			debuff_list.erase(i);
	
	debuff_list.append([DebuffType.STUN, time]);
	next_think = time;

func set_slow(time = 0.0, amount = 0.5) -> void:
	debuff_list.append([DebuffType.SLOWNESS, time, amount]);

func set_impulse(amount: Vector3) -> void:
	impulse = amount;

func set_animation(animation_name: String) -> void:
	if (anims && anims.has_animation(animation_name)):
		anims.play(animation_name);
		anims.seek(0.0);
