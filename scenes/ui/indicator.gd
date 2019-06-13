extends Control

export(bool) var centered = false;
export(Vector2) var offset = Vector2.ZERO;
export(float) var time = 0.0;

var alive_time = 0.0;

func _ready():
	if (time > 0.0):
		alive_time = time;
		set_process(true);
	else:
		set_process(false);

func _process(delta: float) -> void:
	if (alive_time > 0.0):
		alive_time -= delta;
	else:
		set_process(false);
		queue_free();

func init(camera: Camera, world_pos: Vector3) -> void:
	var pos = camera.unproject_position(world_pos);
	
	if (centered):
		pos -= (rect_size / 2.0);
	
	rect_global_position = pos + offset;

func set_text(text: String) -> void:
	$label.text = text;

func set_color(col: Color) -> void:
	$label.add_color_override("font_color", col);
