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

func _quest_completed(quest: QuestManager.Quest) -> void:
	pass

func goto_mainmenu() -> void:
	# switch to main menu
	get_tree().change_scene("res://scenes/main_menu.tscn");
