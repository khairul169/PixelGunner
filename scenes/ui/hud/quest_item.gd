extends Control

func _ready() -> void:
	pass

func set_quest_name(quest_name: String) -> void:
	$title.text = quest_name;

func set_quest_task(task_list: Array) -> void:
	rect_min_size.y += (task_list.size() - 1) * 26;
	
	var task_text: String;
	for i in task_list:
		task_text += i + "\n";
	
	$tasks.bbcode_text = task_text;
