extends Control

# scenes
onready var QuestItem = load("res://scenes/ui/hud/quest_item.tscn");

# reference
onready var controller = $controller;
onready var button_attack = $action_button/attack;
onready var button_reload = $action_button/reload;

func _ready() -> void:
	$menu_btn.connect("pressed", self, "_open_menu");
	
	state_mgr.quest.connect("quests_updated", self, "load_quests");
	load_quests();

func _open_menu() -> void:
	state_mgr.goto_mainmenu();

func set_reloadbutton_clip(clip: int) -> void:
	if (!button_reload):
		return;
	
	if (clip >= 0):
		button_reload.get_node('clip').visible = true;
		button_reload.get_node('clip').text = str(clip);
	else:
		button_reload.get_node('clip').visible = false;

func load_quests() -> void:
	var container = $hud/quests;
	for i in container.get_children():
		i.queue_free();
	
	var quests = state_mgr.quest.get_active_quest();
	for quest in quests:
		var instance = QuestItem.instance();
		container.add_child(instance);
		
		var task_list = [];
		for task in quest.tasks:
			var task_name = state_mgr.quest.get_task_name(task);
			if (task_name):
				task_list.append(task_name);
		
		instance.set_quest_name(quest.name);
		instance.set_quest_task(task_list);
	
	# delay for a frame
	yield(get_tree(), "idle_frame");
	
	# reset container height
	container.rect_size.y = 0.0;
