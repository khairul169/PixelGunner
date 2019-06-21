extends Spatial

const SENSITIVITY = 0.3;

# refs
onready var object = $object;
onready var obj_rotation = $obj_rotation;

var loaded_scenes = {};

func _ready() -> void:
	pass

func set_object(alias: String) -> void:
	var scene;
	if (loaded_scenes.has(alias)):
		scene = loaded_scenes[alias];
	else:
		scene = load("res://models/weapons/" + alias + ".tscn");
		loaded_scenes[alias] = scene;
	
	if (scene):
		for i in object.get_children():
			i.queue_free();
		
		var instance = scene.instance();
		object.add_child(instance);
		obj_rotation.rotation_degrees.y = 0;

func rotate_object(rel: float) -> void:
	obj_rotation.rotation_degrees.y = fmod(obj_rotation.rotation_degrees.y + (SENSITIVITY * rel), 360.0);

func _process(delta: float) -> void:
	if (!is_visible_in_tree()):
		return;
	
	object.transform = object.transform.interpolate_with(obj_rotation.transform, 8.0 * delta);
