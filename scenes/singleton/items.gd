extends Node

# defs
const MATERIAL_STACKS = 25;

# item type
enum {
	TYPE_NONE = 0,
	TYPE_CONSUMABLE,
	TYPE_MATERIAL,
	TYPE_EQUIPMENT
};

# item id
enum {
	ITEM_NONE = 0,
	ITEM_AMMUNITION,
	ITEM_BOLT,
	
	ITEM_REFLEX_SIGHT,
	ITEM_RED_DOT_SIGHT,
	ITEM_FLASHLIGHT,
	ITEM_AP_BULLET,
	ITEM_EXPLOSIVE_BULLET,
	ITEM_MAGAZINE_HC,
	ITEM_MAGAZINE_QC,
	ITEM_TACTICAL_STOCK
};

# item data
var items = {};

func _ready() -> void:
	register_item(ITEM_AMMUNITION, TYPE_NONE, 'ammunition', 'Ammunition', 100);
	register_item(ITEM_BOLT, TYPE_MATERIAL, 'bolt', 'Bolt');

func register_item(id: int, type: int, name: String, label: String, stacks: int = 1) -> void:
	if (type == TYPE_MATERIAL):
		stacks = MATERIAL_STACKS;
	
	if (items.has(id)):
		return;
	
	items[id] = {
		'type': type,
		'stack': stacks,
		'name': name,
		'label': label
	};

func get_item(id: int):
	if (items.has(id)):
		return items[id];
