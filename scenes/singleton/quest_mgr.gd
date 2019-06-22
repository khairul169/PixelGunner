extends Reference
class_name QuestManager

signal quests_updated();
signal quest_added(quest);
signal quest_completed(quest);
signal task_completed(quest, task_id);

enum {
	TASK_NONE = 0,
	TASK_KILL_MONSTER,
	TASK_COLLECT_ITEM,
	TASK_INTERACT_NPC
};

class Quest extends Reference:
	# signals
	signal completed();
	
	# vars
	var quest_mgr: Reference;
	var name: String;
	var tasks = [];
	
	func _init(quest_name: String) -> void:
		name = quest_name;
	
	func add_task(task_type: int, data = null, completed = false) -> int:
		var id = tasks.size();
		tasks.append({
			'id': id,
			'type': task_type,
			'data': data,
			'completed': completed
		});
		
		if (quest_mgr):
			quest_mgr.emit_signal("quests_updated");
		return id;
	
	func get_task(id: int):
		if (id >= 0 && id < tasks.size()):
			return tasks[id];
		return null;
	
	func set_task_data(id: int, data) -> void:
		if (id >= 0 && id < tasks.size()):
			tasks[id].data = data;
		if (quest_mgr):
			quest_mgr.emit_signal("quests_updated");
	
	func set_task_completed(id: int, completed: bool = true) -> void:
		if (id >= 0 && id < tasks.size()):
			tasks[id].completed = completed;
		if (quest_mgr):
			quest_mgr.emit_signal("task_completed", self, id);
			quest_mgr.emit_signal("quests_updated");
		
		var quest_completed = true;
		for i in tasks:
			if (!i.completed):
				quest_completed = false;
				break;
		
		if (quest_completed):
			quest_mgr.remove_quest(self);
			quest_mgr.emit_signal("quest_completed", self);
			emit_signal("completed");

var _active_quest = [];

static func create_quest(name: String, keep_quest: bool = false) -> Quest:
	return Quest.new(name);

func add_quest(quest: Quest) -> void:
	if (!quest in _active_quest):
		quest.quest_mgr = self;
		_active_quest.append(quest);
		emit_signal("quest_added", quest);
		emit_signal("quests_updated");

func remove_quest(quest: Quest) -> void:
	if (quest in _active_quest):
		_active_quest.erase(quest);
		emit_signal("quests_updated");

func get_active_quest() -> Array:
	return _active_quest;

func task_achieved(type: int, args = null) -> void:
	if (type <= 0):
		return;
	
	for quest in _active_quest:
		for task in quest.tasks:
			if (task.type != type || (task.type != TASK_COLLECT_ITEM && task.completed)):
				continue;
			_check_task(quest, task, type, args);

func _check_task(quest: Quest, task: Dictionary, type: int, args) -> void:
	var data = task.data;
	
	match (type):
		TASK_KILL_MONSTER:
			if (data.monster != args):
				return;
			
			var num = data['_num'] + 1 if data.has('_num') else 1;
			if (num >= data.count):
				quest.set_task_completed(task.id);
			
			# update data
			data['_num'] = int(clamp(num, 0, data.count));
			quest.set_task_data(task.id, data);
		
		TASK_COLLECT_ITEM:
			var num = args.get_item_amount(data.item);
			quest.set_task_completed(task.id, (num >= data.count));
			
			# update data
			data['_num'] = int(clamp(num, 0, data.count));
			quest.set_task_data(task.id, data);
		
		TASK_INTERACT_NPC:
			var npc_id = data.npc if data.has('npc') else -1;
			var name = data.name if data.has('name') else null;
			
			if (args is NPC):
				if (args.npc_type == npc_id && args.npc_name == name):
					quest.set_task_completed(task.id);
		
		_:
			quest.set_task_completed(task.id);

func get_task_name(task: Dictionary):
	if (!task.has('type')):
		return null;
	
	var name;
	match (task.type):
		TASK_KILL_MONSTER:
			name = _task_kill_monster(task, task.data);
		
		TASK_COLLECT_ITEM:
			name = _task_collect_object(task, task.data);
		
		TASK_INTERACT_NPC:
			name = _task_interact_npc(task, task.data);
	
	if (task.completed):
		name = _bb_completed(name);
	return name;

func _bb_object(name: String) -> String:
	return " [color=#edef6b]" + name + "[/color]";

func _bb_counter(current: int, count: int) -> String:
	return " [color=#8edb4e](" + str(current, "/", count) + ")[/color]";

func _bb_completed(text: String) -> String:
	return "[s]" + text + "[/s]";

func _task_kill_monster(task, data):
	if (!data.has('monster') || !data.has('count')):
		return null;
	
	var monster_data = Entities.get_monster_data(data.monster);
	var task_counter = data['_num'] if data.has('_num') else 0;
	return str("Find and kill", _bb_object(monster_data.name), _bb_counter(task_counter, data.count));

func _task_collect_object(task, data):
	if (!data.has('item') || !data.has('count')):
		return null;
	
	var item_data = Items.get_item(data.item);
	var task_counter = data['_num'] if data.has('_num') else 0;
	return str("Collect", _bb_object(item_data.label), _bb_counter(task_counter, data.count));

func _task_interact_npc(task, data):
	if (data.has('npc') && data.has('name')):
		return "Talk with" + _bb_object(str(data.name).capitalize());
