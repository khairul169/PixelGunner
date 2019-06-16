extends Spatial

func _ready() -> void:
	var animsplayer = $player.find_node('AnimationPlayer');
	if (animsplayer):
		animsplayer.get_animation('idle_rifle').loop = true;
		animsplayer.play('idle_rifle');
