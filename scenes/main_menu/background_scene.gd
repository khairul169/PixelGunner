extends Spatial

onready var camera = $camera;

var camera_transform = Transform();

func _ready() -> void:
	var animsplayer = $player.find_node('AnimationPlayer');
	if (animsplayer):
		animsplayer.get_animation('idle_rifle').loop = true;
		animsplayer.play('idle_rifle');
	
	camera_transform = camera.transform;

func _process(delta: float) -> void:
	camera.transform = camera.transform.interpolate_with(camera_transform, 8.0 * delta);
