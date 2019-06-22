extends KinematicBody
class_name NPC

# editor var
export (Entities.NPC) var npc_type;
export (String) var npc_name;

# refs
onready var anims: AnimationPlayer = $body.find_node('AnimationPlayer');

# enums
enum State {
	IDLE = 0,
	GIVING_SOMETHING
};

# vars
var velocity := Vector3.ZERO;
var interact_with;
var state = State.GIVING_SOMETHING;

func _ready() -> void:
	# register npc
	add_to_group("npc");
	
	if (npc_name):
		$floating_bar.init(str(npc_name).capitalize());
	else:
		$floating_bar.queue_free();
	
	anims.get_animation('idle_alt').loop = true;
	anims.play('idle_alt');

func _physics_process(delta: float) -> void:
	var gv = velocity.y - (19.6 * delta);
	velocity = Vector3.ZERO;
	velocity.y = gv;
	velocity = move_and_slide(velocity, Vector3.UP);

func interact(caller: Node):
	interact_with = caller;
	
	var msg = [];
	if (state == State.GIVING_SOMETHING):
		msg.append(Conversation.create_message(npc_name, "Hey friend!"));
		msg.append(Conversation.create_message(npc_name, "Here is some cake for you."));
		msg.append(Conversation.create_message(npc_name, "..."));
		msg.append(Conversation.create_message(npc_name, "Take this! :p"));
	else:
		msg.append(Conversation.create_message(npc_name, "... hi!"));
		msg.append(Conversation.create_message(npc_name, "What happened?"));
	return msg;

func _interact_ended():
	if (!interact_with):
		return;
	
	if (interact_with is Player && state == State.GIVING_SOMETHING):
		interact_with.give_item(Items.ITEM_BOLT, 10);
		state = State.IDLE;
	
	interact_with = null;
