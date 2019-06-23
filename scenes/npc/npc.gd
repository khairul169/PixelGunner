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
	BUSY,
	QUEST_ENDED
};

# vars
var velocity := Vector3.ZERO;
var player: Player;
var state = State.IDLE;

func _ready() -> void:
	# register npc
	add_to_group("npc");
	
	GameState.quest.connect("quest_added", self, "_quest_added");
	GameState.quest.connect("quest_completed", self, "_quest_completed");
	
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
	if (!caller is Player):
		return;
	
	# set player reference
	player = caller;
	
	var msg = [];
	match (state):
		State.IDLE:
			msg.append(Conversation.create_message(npc_name, "Hey friend!"));
			msg.append(Conversation.create_message(npc_name, "Here is some cake for you."));
			msg.append(Conversation.create_message(npc_name, "..."));
			msg.append(Conversation.create_message(npc_name, "Take this! :p"));
		
		State.QUEST_ENDED:
			msg.append(Conversation.create_message(npc_name, "Welcome back! Thank you for your hard work..."));
			msg.append(Conversation.create_message(npc_name, "Here is some reward i have for you."));
		
		_:
			msg.append(Conversation.create_message(npc_name, "... hi!"));
			msg.append(Conversation.create_message(npc_name, "What happened?"));
	return msg;

func _interact_ended():
	if (state == State.IDLE && player):
		start_quest();

func _quest_added(quest) -> void:
	if (quest.id == npc_name):
		state = State.BUSY;
	
	if (quest.id == npc_name + "_end"):
		state = State.QUEST_ENDED;

func _quest_completed(quest) -> void:
	if (quest.id == npc_name):
		quest_completed();
		state = State.QUEST_ENDED;
	
	if (quest.id == npc_name + "_end" && player):
		give_reward();
		state = State.IDLE;

func start_quest() -> void:
	# create quest
	var quest = GameState.quest.create_quest(npc_name, "Hello world!");
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
	if (player):
		player.give_item(Items.ITEM_BOLT, 8);

func quest_completed() -> void:
	# create quest
	var new_quest = GameState.quest.create_quest(npc_name + "_end", "Hello world!");
	new_quest.add_task(GameState.quest.TASK_INTERACT_NPC, {
		'npc': npc_type,
		'name': npc_name
	});
	GameState.quest.add_quest(new_quest);

func give_reward() -> void:
	# quest reward
	player.give_item(Items.ITEM_AMMUNITION, 80);
