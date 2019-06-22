extends Node

# defs
const INTERACTION_RANGE = 2.0;

# reference
onready var player: Player = get_parent();

# vars
var target = null;
var can_interact: bool = false;

func _ready() -> void:
	call_deferred("_create_area");

func _create_area() -> void:
	# collision shape
	var col = CollisionShape.new();
	col.shape = SphereShape.new();
	col.shape.radius = INTERACTION_RANGE;
	
	# attach area to player
	var area = Area.new();
	area.add_child(col);
	player.add_child(area);
	
	# connect signals
	area.connect("body_entered", self, "_object_enter");
	area.connect("body_exited", self, "_object_exit");

func _object_enter(object: Node) -> void:
	if (object is NPC && !target):
		target = object;
		can_interact = true;

func _object_exit(object: Node) -> void:
	if (target && target == object):
		target = null;
		can_interact = false;

func go_interact() -> void:
	if (!target):
		return;
	
	player.stop(0.5);
	player.set_looking_at(target);
	
	print('interacting with ', target.name);
	
	GameState.quest.task_achieved(QuestManager.TASK_INTERACT_NPC, target);
