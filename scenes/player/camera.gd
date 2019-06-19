extends Spatial
class_name PlayerCamera

const OFFSET = Vector3(2, 8, 3);
const INTERPOLATION = 4.0;

onready var camera_node = $cam;
var player_node;

var camera_dir := Basis();
var origin := Vector3.ZERO;
var fov = 60.0;

func _ready() -> void:
	call_deferred("init");

func init() -> void:
	# get player node
	player_node = get_parent().get_node('player');
	
	origin = global_transform.origin;
	
	# set camera offset
	camera_node.transform.origin = OFFSET;
	
	# get camera direction
	var cam_transform: Transform = camera_node.transform;
	cam_transform.origin.y = 0.0;
	camera_dir = cam_transform.looking_at(Vector3.ZERO, Vector3.UP).basis;
	
	# set camera looking at center point
	camera_node.transform = camera_node.transform.looking_at(Vector3.ZERO, Vector3.UP);

func _process(delta: float) -> void:
	if (!player_node):
		return;
	
	if (abs(camera_node.fov-fov) > 0.1):
		camera_node.fov = lerp(camera_node.fov, fov, 4.0 * delta);
	
	origin = origin.linear_interpolate(player_node.global_transform.origin, INTERPOLATION * delta);
	global_transform.origin = origin;
