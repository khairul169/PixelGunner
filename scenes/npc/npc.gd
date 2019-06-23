extends KinematicBody
class_name NPC

const QUEST_TEST = 'npc_questtest';

# editor var
export (Entities.NPC) var npc_type;
export (String) var npc_name;

# refs
onready var anims: AnimationPlayer = $body.find_node('AnimationPlayer');

# enums
enum State {
	IDLE = 0,
	BUSY
};

# vars
var velocity := Vector3.ZERO;
var interact_with;
var state = State.IDLE;

func _ready() -> void:
	# register npc
	add_to_group("npc");
	
	GameState.quest.connect("quest_added", self, "_quest_added");
	
	if (npc_name):
		$floating_bar.init(str(npc_name).capitalize());
	else:
		$floating_bar.queue_free();
	
	anims.get_animation('idle_alt').loop = true;
	anims.play('idle_alt');

func _quest_added(quest) -> void:
	if (quest.id == QUEST_TEST):
		state = State.BUSY;

func _physics_process(delta: float) -> void:
	var gv = velocity.y - (19.6 * delta);
	velocity = Vector3.ZERO;
	velocity.y = gv;
	velocity = move_and_slide(velocity, Vector3.UP);

func interact(caller: Node):
	interact_with = caller;
	
	var msg = [];
	if (state == State.IDLE):
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
	
	if (interact_with is Player && state == State.IDLE):
		# create quest
		var quest = GameState.quest.create_quest(QUEST_TEST, "Hello world!");
		quest.add_task(GameState.quest.TASK_KILL_MONSTER, {
			'monster': Entities.Monster.CROG,
			'count': 1
		});
		quest.add_task(GameState.quest.TASK_COLLECT_ITEM, {
			'item': Items.ITEM_BOLT,
			'count': 10
		});
		GameState.quest.add_quest(quest);
		
		# give quest item
		interact_with.give_item(Items.ITEM_BOLT, 10);
	
	interact_with = null;
