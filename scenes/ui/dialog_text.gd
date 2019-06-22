extends Label

var available_text: String;
var delay = 0.0;
var next_think = 0.0;
var text_loaded = false;
var animating = false;

func _ready() -> void:
	set_process(false);

func _process(delta: float) -> void:
	if (!text_loaded):
		return;
	
	if (next_think > 0.0):
		next_think -= delta;
	
	if (next_think <= 0.0):
		process_text();
		next_think = delay;

func animate_text(msg: String) -> void:
	available_text = msg;
	delay = clamp(1.0 / msg.length(), 0.02, 0.1);
	next_think = 0.0;
	text_loaded = true;
	text = "";
	set_process(true);

func process_text() -> void:
	var chars = available_text.substr(0, 1);
	text += chars;
	available_text = available_text.substr(1, available_text.length() - 1);
	animating = true;
	
	if (available_text.empty()):
		stop();

func skip_msg() -> void:
	text += available_text;
	available_text = "";
	stop();

func stop() -> void:
	text_loaded = false;
	set_process(false);
	animating = false;
