extends Node

# classes
class PlayerState extends Reference:
	var weapon;

# vars
var quest: QuestManager;
var player := PlayerState.new();

func _ready() -> void:
	GameData.connect("data_updated", self, "_data_updated");
	
	# initialize state
	reset_game();
	player.weapon = null;

func _data_updated() -> void:
	# get current weapon data
	var wpn_data = GameData.get_weapon_data(-1);

	player.weapon = {
		'id': wpn_data.id,
		'equip': wpn_data.equip if wpn_data.has('equip') else null,
		'stats': Weapon.get_stats(wpn_data)
	} if wpn_data && wpn_data.has('id') else null;

func reset_game() -> void:
	# initialize quest manager
	quest = QuestManager.new();
	quest.connect("quest_completed", self, "_quest_completed");
	
	# create quest
	var quest1 = QuestManager.create_quest("New Quest");
	quest1.connect("completed", self, "goto_quest3");
	quest1.add_task(QuestManager.TASK_KILL_MONSTER, {
		'monster': Entities.Monster.CROG,
		'count': 2
	});
	quest1.add_task(QuestManager.TASK_KILL_MONSTER, {
		'monster': Entities.Monster.RANGED,
		'count': 1
	});
	quest1.add_task(QuestManager.TASK_COLLECT_ITEM, {
		'item': Items.ITEM_BOLT,
		'count': 5
	});
	quest.add_quest(quest1);

	var quest2 = QuestManager.create_quest("Simple Quest");
	quest2.add_task(QuestManager.TASK_KILL_MONSTER, {
		'monster': Entities.Monster.CROG,
		'count': 10
	});
	quest2.add_task(QuestManager.TASK_INTERACT_NPC, {
		'npc': Entities.NPC.TRADER,
		'name': 'Derick'
	});
	quest.add_quest(quest2);

func _quest_completed(quest_obj) -> void:
	print('quest completed ', quest_obj.name);

func goto_quest3() -> void:
	var quest3 = QuestManager.create_quest("New Quest");
	quest3.add_task(QuestManager.TASK_COLLECT_ITEM, {
		'item': Items.ITEM_BOLT,
		'count': 20
	});
	quest3.add_task(QuestManager.TASK_INTERACT_NPC, {
		'npc': Entities.NPC.TRADER,
		'name': 'Derick'
	});
	quest.add_quest(quest3);

func goto_mainmenu() -> void:
	# switch to main menu
	get_tree().change_scene("res://scenes/main_menu.tscn");
