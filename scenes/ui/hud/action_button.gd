extends Control

# signals
signal pressed();
signal released();

# vars
var pressed := false;
var touch_id := -1;

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE;

func _unhandled_input(event: InputEvent) -> void:
	if (!is_visible_in_tree()):
		return;
	
	if (event is InputEventMouseButton):
		var pos = event.position;
		if (event.pressed):
			if (get_global_rect().has_point(pos)):
				pressed = true;
				get_tree().set_input_as_handled();
				emit_signal("pressed");
		else:
			pressed = false;
			emit_signal("released");
	
	if (event is InputEventScreenTouch):
		var pos = event.position;
		if (event.pressed):
			if (get_global_rect().has_point(pos) && touch_id < 0):
				pressed = true;
				touch_id = event.index;
				get_tree().set_input_as_handled();
				emit_signal("pressed");
		else:
			if (touch_id == event.index):
				pressed = false;
				touch_id = -1;
				emit_signal("released");
