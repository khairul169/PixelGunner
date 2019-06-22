extends Control
class_name Conversation

# signals
signal dialog_completed();

# refs
onready var msg_name = $message/name;
onready var msg_text = $message/text;

# defs
enum {
	DLG_MESSAGE = 0,
	DLG_OPTIONS,
	DLG_QUEST
};

# vars
var conversation = [];
var is_busy = false;
var can_advance = false;

func _ready() -> void:
	hide();

func _input(event: InputEvent) -> void:
	if (!is_visible_in_tree()):
		return;
	
	if (event is InputEventMouseButton && event.pressed && !is_busy):
		get_tree().set_input_as_handled();
		next();

func _dialog_completed() -> void:
	emit_signal("dialog_completed");

func start_dialog() -> void:
	if (conversation.empty()):
		return;
	
	var msg = conversation[0];
	conversation.remove(0);
	can_advance = true;
	
	var msg_type = msg[0];
	if (msg_type == DLG_MESSAGE):
		$message/name.text = msg[1];
		$message/text.animate_text(msg[2]);

func show_conversation(messages: Array) -> void:
	if (messages.empty()):
		return;
	
	conversation = messages;
	show();
	start_dialog();

func next() -> void:
	if (can_advance && msg_text.animating):
		can_advance = false;
		msg_text.skip_msg();
		return;
	
	if (conversation.empty()):
		_dialog_completed();
		hide();
	else:
		start_dialog();

func skip() -> void:
	pass

static func create_message(obj_name: String, msg: String) -> Array:
	return [DLG_MESSAGE, obj_name, msg];

static func create_options(options: Array) -> Array:
	return [DLG_OPTIONS, options];

static func create_quest(quest) -> Array:
	return [DLG_QUEST, quest.name];
