extends Node

# defs
const INTERACTION_RANGE = 2.0;

# reference
onready var player: Player = get_parent();

# vars
var nearest_object;
var can_interact = false;
var interact_with;

func _ready() -> void:
	call_deferred("_initialize");

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

func _initialize() -> void:
	player.ui.conversation.connect("dialog_completed", self, "_dialog_completed");
	_create_area();

func _object_enter(object: Node) -> void:
	if (object is NPC && !nearest_object):
		nearest_object = object;
		can_interact = true;

func _object_exit(object: Node) -> void:
	if (nearest_object && nearest_object == object):
		nearest_object = null;
		can_interact = false;

func _dialog_completed() -> void:
	if (!interact_with):
		return;
	
	player.camera.fov = 60.0;
	can_interact = true;
	
	if (interact_with.has_method('_interact_ended')):
		interact_with.call('_interact_ended');
	
	GameState.quest.task_achieved(QuestManager.TASK_INTERACT_NPC, interact_with);

func go_interact() -> void:
	if (!nearest_object):
		return;
	
	var npc = nearest_object;
	var msg = npc.interact(player) if npc.has_method('interact') else null;
	if (!msg || typeof(msg) != TYPE_ARRAY || msg.empty()):
		return;
	
	player.stop(0.5);
	player.set_looking_at(npc);
	player.camera.fov = 50.0;
	
	interact_with = npc;
	can_interact = false;
	player.ui.conversation.show_conversation(msg);
