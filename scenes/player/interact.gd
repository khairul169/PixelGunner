extends Node

# defs
const INTERACTION_RANGE = 2.0;

# reference
onready var player: Player = get_parent();

func _ready() -> void:
	call_deferred("_create_area");

func _create_area() -> void:
	# collision shape
	var col = CollisionShape.new();
	col.shape = SphereShape.new();
	col.shape.radius = INTERACTION_RANGE;
	
	# attach area to player
	var area = Area.new();
	area.add_child(col);
	player.add_child(area);
	
	# connect signals
	area.connect("body_entered", self, "_object_enter");
	area.connect("body_exited", self, "_object_exit");

func _object_enter(object: Node) -> void:
	pass

func _object_exit(object: Node) -> void:
	pass
