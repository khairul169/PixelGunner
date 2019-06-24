extends Spatial

# defs
const HEIGHT = 1.4;
const INTERPOLATION = 10.0;
const SENSITIVITY = 0.2;

# refs
onready var touch_area = $base/touch_area;
onready var pitch = $pitch;
onready var camera_node = $pitch/cam;
var player_node;

# vars
var camera_dir := Basis();
var origin := Vector3.ZERO;
var fov = 60.0;
var dragging := false;
var touch_id = -1;

func _ready() -> void:
	origin = global_transform.origin;
	get_tree().connect("screen_resized", self, "_screen_resized");
	call_deferred("_initialize");

func _initialize() -> void:
	# get player node
	player_node = get_parent().get_node('player');

func _screen_resized() -> void:
	# resize touch area
	var base_size = $base.rect_size;
	$base/touch_area.rect_size = base_size * Vector2(0.5, 1);
	$base/touch_area.rect_position.x = base_size.x * 0.5;

func _unhandled_input(event: InputEvent) -> void:
	if (OS.has_touchscreen_ui_hint()):
		# touch screen input
		if (event is InputEventScreenTouch):
			if (event.pressed):
				if (touch_area.get_global_rect().has_point(event.position) && !dragging):
					dragging = true;
					touch_id = event.index;
					get_tree().set_input_as_handled();
			else:
				if (dragging && event.index == touch_id):
					dragging = false;
					touch_id = -1;
		
		if (event is InputEventScreenDrag && dragging):
			if (event.index == touch_id):
				_rotate(event.relative);
	else:
		# mouse input
		if (event is InputEventMouseButton):
			if (event.pressed):
				if (touch_area.get_global_rect().has_point(event.position) && !dragging):
					dragging = true;
					get_tree().set_input_as_handled();
			else:
				if (dragging):
					dragging = false;
		
		if (event is InputEventMouseMotion && dragging):
			_rotate(event.relative);

func _rotate(rel: Vector2) -> void:
	# rotate camera
	rotation_degrees.y = fmod(rotation_degrees.y - rel.x * SENSITIVITY, 360);
	pitch.rotation_degrees.x = clamp(pitch.rotation_degrees.x - rel.y * SENSITIVITY, -60.0, 60.0);
	
	# set new camera basis
	camera_dir = camera_node.global_transform.basis;

func _process(delta: float) -> void:
	if (!player_node):
		return;
	
	# interpolate to player position
	origin = origin.linear_interpolate(player_node.global_transform.origin, INTERPOLATION * delta);
	global_transform.origin = origin + Vector3(0, HEIGHT, 0);
