extends Control

func _ready() -> void:
	for i in $panel/container/items.get_children():
		i.connect("pressed", self, "_test", [i]);

func _test(item) -> void:
	print('jajja ', item.name);
