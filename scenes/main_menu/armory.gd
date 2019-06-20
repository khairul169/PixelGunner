extends Control

func _ready() -> void:
	$panel/weapon.armory = self;

func set_slot_value(value: int, max_capacity: int) -> void:
	$header/slots.text = str(value, "/", max_capacity);
