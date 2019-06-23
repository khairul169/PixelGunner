extends "res://scenes/npc/npc.gd"

# enums
enum State {
	IDLE = 0,
	BUSY,
	QUEST_ENDED
};

var state = State.IDLE;
var player: Player;

func _ready() -> void:
	GameState.quest.connect("quest_added", self, "_quest_added");
	GameState.quest.connect("quest_completed", self, "_quest_completed");

func interact(caller: Node):
	if (!caller is Player):
		return;
	
	# set player reference
	player = caller;
	
	# disable player control
	player.control_enabled = false;
	
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
	# enable player control
	player.control_enabled = true;
	
	if (state == State.IDLE && player):
		start_quest();

func _quest_added(quest) -> void:
	if (quest.id == quest_id(npc_name, 0)):
		state = State.BUSY;
	
	if (quest.id == quest_id(npc_name, 1)):
		state = State.QUEST_ENDED;

func _quest_completed(quest) -> void:
	if (quest.id == quest_id(npc_name, 0)):
		quest_completed();
		state = State.QUEST_ENDED;
	
	if (quest.id == quest_id(npc_name, 1) && player):
		give_reward();
		state = State.IDLE;

func start_quest() -> void:
	# create quest
	var quest = GameState.quest.create_quest(quest_id(npc_name, 0), "Hello world!");
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
	var new_quest = GameState.quest.create_quest(quest_id(npc_name, 1), "Hello world!");
	new_quest.add_task(GameState.quest.TASK_INTERACT_NPC, {
		'npc': npc_type,
		'name': npc_name
	});
	GameState.quest.add_quest(new_quest);

func give_reward() -> void:
	# quest reward
	player.give_item(Items.ITEM_AMMUNITION, 80);

static func quest_id(name: String, num: int = 0) -> String:
	return str('quest_npc-', name.to_lower(), num);
