extends Node

# signals
signal item_updated();

# reference
onready var player: Player = get_parent();

# vars
var items = [];

func _ready() -> void:
	pass

func _item_updated() -> void:
	emit_signal("item_updated");
	
	# task
	state_mgr.quest.task_achieved(state_mgr.quest.TASK_COLLECT_ITEM, self);
	
	var text = "";
	for item in items:
		var item_name = Items.get_item(item.id).label;
		text += str(item_name, " (", item.amount, ")\n");
	
	$Label.text = text;

func add_item(item_id: int, amount: int) -> void:
	if (!Items.items.has(item_id) || amount <= 0):
		return;
	
	var max_stacks = Items.get_item(item_id).stack;
	var has_stacks = _find_fillable_slot(item_id);
	
	if (has_stacks >= 0 && has_stacks < items.size()):
		var cur_amount = items[has_stacks].amount;
		var filled = int(min(cur_amount + amount, max_stacks));
		items[has_stacks].amount = filled;
		amount -= (filled - cur_amount);
		_item_updated();
	
	if (amount <= 0):
		return;
	
	if (amount <= max_stacks):
		items.append({'id': item_id, 'amount': amount});
	else:
		var num = int(floor(float(amount) / max_stacks));
		for i in range(num):
			items.append({'id': item_id, 'amount': max_stacks});
		var f = amount % max_stacks;
		if (f > 0):
			items.append({'id': item_id, 'amount': f});
	
	# call signal
	_item_updated();

func _find_fillable_slot(item_id: int) -> int:
	var max_stacks = Items.get_item(item_id).stack;
	for i in range(items.size()):
		if (items[i].id == item_id && items[i].amount < max_stacks):
			return i;
	return -1;

func get_item_by_id(id: int):
	for i in items:
		if (i.id == id):
			return i;

func set_item_amount(item, amount: int) -> void:
	if (typeof(item) == TYPE_INT && item >= 0 && item < items.size()):
		items[item].amount = amount;
	elif (item is Dictionary && item.has('amount')):
		item.amount = amount;
	_item_updated();

func get_item_amount(item_id: int) -> int:
	var amount = 0;
	for item in items:
		amount += item.amount if item.id == item_id else 0;
	return amount;

func remove_item(item_id: int, amount: int) -> int:
	var needed = amount;
	for item in items:
		if (item.id != item_id):
			continue;
		
		var d = int(min(needed, item.amount));
		needed = needed - d;
		
		item.amount -= d;
		if (item.amount <= 0):
			items.erase(item);
		
		if (needed <= 0):
			break;
	
	# call signal
	_item_updated();
	return (amount - needed);

func remove_item_stack(slot: int) -> void:
	if (slot >= 0 && slot < items.size()):
		items.remove(slot);
		_item_updated();

func resupply_ammo() -> void:
	var weapon = PlayerWeapon.get_weapon(player.weapon);
	if (!weapon):
		return;
	
	var ammo = 0;
	match (weapon.wpn_class):
		PlayerWeapon.CLASS_AR:
			ammo = 20;
		PlayerWeapon.CLASS_HG, PlayerWeapon.CLASS_SMG:
			ammo = 30;
		PlayerWeapon.CLASS_SG, PlayerWeapon.CLASS_SR:
			ammo = 10;
	
	var item = get_item_by_id(Items.ITEM_AMMUNITION);
	if (item):
		set_item_amount(item, ammo);
	else:
		add_item(Items.ITEM_AMMUNITION, ammo);
