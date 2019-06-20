extends Reference
class_name Items

const MATERIAL_STACKS = 25;

enum {
	TYPE_NONE = 0,
	TYPE_CONSUMABLE,
	TYPE_MATERIAL
};

enum {
	ITEM_NONE = 0,
	ITEM_AMMUNITION,
	ITEM_BOLT
};

const items = {
	ITEM_AMMUNITION: {
		'type': TYPE_NONE,
		'stack': 100,
		'name': 'ammunition',
		'label': 'Ammunition'
	},
	
	ITEM_BOLT: {
		'type': TYPE_MATERIAL,
		'stack': MATERIAL_STACKS,
		'name': 'bolt',
		'label': 'Bolt'
	}
};

static func get_item(id: int):
	if (items.has(id)):
		return items[id];
