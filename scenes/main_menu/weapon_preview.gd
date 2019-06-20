extends Spatial

const SENSITIVITY = 0.3;

# refs
onready var object = $object;
onready var obj_rotation = $obj_rotation;

func _ready() -> void:
	pass

func rotate_object(rel: float) -> void:
	obj_rotation.rotation_degrees.y = fmod(obj_rotation.rotation_degrees.y + (SENSITIVITY * rel), 360.0);

func _process(delta: float) -> void:
	if (!is_visible_in_tree()):
		return;
	
	object.transform = object.transform.interpolate_with(obj_rotation.transform, 8.0 * delta);
