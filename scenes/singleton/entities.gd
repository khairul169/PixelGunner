extends Reference
class_name Entities

enum NPC {
	NONE = 0,
	TELEPORTER,
	TRADER,
	ENHANCHER,
	CRAFTER,
	QUEST_GIVER
}

enum Monster {
	CROG = 0,
	RANGED
};

const monster_data = [
	{
		'alias': 'crog',
		'name': 'Crog'
	},
	{
		'alias': 'ranged',
		'name': 'Ranged'
	}
];

static func get_monster_data(id: int):
	if (id >= 0 && id < monster_data.size()):
		return monster_data[id];
	return null;
