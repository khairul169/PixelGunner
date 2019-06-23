extends KinematicBody
class_name NPC

# editor var
export (Entities.NPC) var npc_type;
export (String) var npc_name;

# refs
onready var anims: AnimationPlayer = $body.find_node('AnimationPlayer');

# vars
var velocity := Vector3.ZERO;

func _ready() -> void:
	# register npc
	add_to_group("npc");
	
	if (npc_name):
		$floating_bar.init(str(npc_name).capitalize());
	else:
		$floating_bar.queue_free();
	
	anims.get_animation('idle_alt').loop = true;
	anims.play('idle_alt');

func _physics_process(delta: float) -> void:
	var gv = velocity.y - (19.6 * delta);
	velocity = Vector3.ZERO;
	velocity.y = gv;
	velocity = move_and_slide(velocity, Vector3.UP);

func interact(caller: Node):
	return null;

func _interact_ended():
	pass
