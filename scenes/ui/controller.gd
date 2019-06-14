extends Control

signal pressed();
signal released(dir);

# editor var
export(Texture) var base_button;
export(Texture) var button;
export(float) var max_distance = 80.0;

# vars
var pressed := false;
var start_pos := Vector2.ZERO;
var cur_pos := Vector2.ZERO;
var dir := Vector3.ZERO;
var touch_id := -1;

func _ready() -> void:
	get_tree().connect("screen_resized", self, "update_container");
	call_deferred('update_container');

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton):
		var pos = event.position;
		if (event.pressed):
			if (get_global_rect().has_point(pos)):
				handle_input(pos, true);
				get_tree().set_input_as_handled();
		else:
			handle_input(pos, false);
	
	if (event is InputEventMouseMotion):
		motion_update(event.position);
	
	if (event is InputEventScreenTouch):
		var pos = event.position;
		if (event.pressed):
			if (get_global_rect().has_point(pos) && touch_id < 0):
				handle_input(pos, true);
				touch_id = event.index;
				get_tree().set_input_as_handled();
		else:
			if (touch_id == event.index):
				handle_input(pos, false);
				touch_id = -1;
	
	if (event is InputEventScreenDrag && event.index == touch_id):
		motion_update(event.position);

func _draw() -> void:
	if (!pressed || !base_button || !button):
		return;
	
	# base button
	draw_texture(base_button, start_pos - (base_button.get_size() / 2.0) - rect_global_position);
	
	# button
	draw_texture(button, cur_pos - (button.get_size() / 2.0) - rect_global_position);

func update_container() -> void:
	if (!get_parent() is Control):
		return;
	
	var parent_size = get_parent().rect_size;
	rect_position = parent_size * Vector2(0.0, 0.5);
	rect_size = parent_size * Vector2(0.4, 0.5);

func handle_input(pos, is_pressed) -> void:
	# set pressed value
	pressed = is_pressed;
	
	if (pressed):
		start_pos = pos;
		cur_pos = pos;
		emit_signal("pressed");
	else:
		start_pos = Vector2.ZERO;
		cur_pos = Vector2.ZERO;
		emit_signal("released", dir);
	
	dir = Vector3.ZERO;
	update();

func motion_update(pos) -> void:
	if (!pressed):
		return;
	
	# calculate direction
	var input_dir = pos - start_pos;
	var distance = input_dir.length();
	input_dir = input_dir.normalized();
	cur_pos = start_pos + (input_dir * clamp(distance, 0.0, max_distance));
	
	# set controller dir
	dir = Vector3(input_dir.x, 0, input_dir.y);
	update();
