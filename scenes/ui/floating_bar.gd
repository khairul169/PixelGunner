extends Control

# editor config
export(Vector2) var offset = Vector2(0, -20.0);
export(float) var healthbar_height = 5;
export(Color) var healthbar_color = Color('#d63d3d');
export(bool) var always_visible = false;

# reference
onready var health_bar = get_node("health/bar");

# vars
var parent: Spatial;
var camera: Camera;
var health = 0.0;
var health_max = 0.0;

func _ready() -> void:
	parent = get_parent();
	camera = parent.get_viewport().get_camera();
	
	parent.connect("health_changed", self, "_health_changed");
	
	health_bar.get_parent().rect_size.y = healthbar_height;
	health_bar.color = healthbar_color;

func init(barname: String, max_health: float) -> void:
	$name.text = barname;
	health_max = max_health;

func _health_changed(new_health: float) -> void:
	if (!parent is Spatial || !camera):
		return;
	
	if (health_max > 0.0):
		health = clamp(new_health / health_max, 0.0, 1.0);
	else:
		health = 0.0;
	
	if ((health <= 0.0 || health >= 1.0) && !always_visible):
		visible = false;
		set_process(false);
	else:
		visible = true;
		set_process(true);

func _process(delta: float) -> void:
	var pos = camera.unproject_position(parent.global_transform.origin + Vector3.UP);
	pos -= rect_size / 2.0;
	pos += offset;
	
	rect_global_position = pos;
	health_bar.rect_size.x = health_bar.get_parent().rect_size.x * health;
