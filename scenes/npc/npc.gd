extends KinematicBody
class_name NPC

# defs
enum NPCType {
	NONE = 0,
	TELEPORTER,
	TRADER,
	ENHANCHER,
	CRAFTER
}

const NPCName = [
	'',
	'Teleporter',
	'Trader',
	'Enhancher',
	'Crafter'
];

# editor var
export (NPCType) var npc_type = NPCType.NONE;

# refs
onready var anims: AnimationPlayer = $body.find_node('AnimationPlayer');

# vars
var velocity := Vector3.ZERO;

func _ready() -> void:
	anims.get_animation('idle_alt').loop = true;
	anims.play('idle_alt');
	
	var npc_name;
	if (npc_type >= 0 && npc_type < NPCName.size()):
		npc_name = NPCName[npc_type];
	
	if (npc_name):
		$floating_bar.init(npc_name);
	else:
		$floating_bar.queue_free();

func _physics_process(delta: float) -> void:
	var gv = velocity.y - (19.6 * delta);
	velocity = Vector3.ZERO;
	velocity.y = gv;
	velocity = move_and_slide(velocity, Vector3.UP);
