// Horde pressure: make room for genuinely stronger undead when the
// ordinary or milestone population limit has been reached.
// This is a quiet retirement, not a kill: no money, loot, gibbing or XP.

const f32 ZG_HORDE_SAFE_REPLACEMENT_DISTANCE = 192.0f;
const u32 ZG_HORDE_REGULAR_REPLACEMENT_INTERVAL = 30;
const u32 ZG_HORDE_BOSS_REPLACEMENT_INTERVAL = 5;

// Only explicitly ranked units participate. Unknown/custom creatures
// can never be removed by accident.
int ZGHordePower(const string &in name)
{
	if (name == "zchicken") return 1;
	if (name == "catto") return 2;
	if (name == "skeleton" || name == "skeleton2") return 3;
	if (name == "zombie" || name == "zombie2") return 4;
	if (name == "plantzombie" || name == "bloodzombie" || name == "evilzombie") return 5;
	if (name == "zombieknight") return 6;
	if (name == "gasbag" || name == "flamebag") return 7;
	if (name == "immolator") return 8;
	if (name == "greg" || name == "greg2") return 9;
	if (name == "wraith" || name == "wraith2") return 10;
	if (name == "zbison" || name == "zbison2") return 11;
	if (name == "pbanshee") return 12;
	if (name == "horror") return 13;
	if (name == "writher") return 14;
	if (name == "digger") return 15;
	if (name == "abomination" || name == "pankou" ||
		name == "pbrute" || name == "phellknight" || name == "pcrawler")
		return 16;
	return 0;
}

// Retire only basic naturally spawned wildlife / undead, never a boss,
// an undead player, portal summon, Necromancer summon or carried creature.
bool ZGIsReplaceableHordeMob(CBlob @blob)
{
	if (blob is null || blob.hasTag("dead") || !blob.hasTag("zombie") ||
		blob.hasTag("pzombie") || blob.hasTag("necromancer_zombie") ||
		blob.hasTag("undeadplayer") || blob.hasTag("zg_boss_spawn") ||
		blob.hasTag("zg_horde_retired") || blob.hasTag("chomping") ||
		blob.getPlayer() !is null || blob.isAttached() ||
		blob.getTeamNum() != 255)
		return false;

	// Zombies can hold items or corpses. Never delete a player's loot
	// just to improve the composition of a distant horde.
	CInventory @inv = blob.getInventory();
	if (inv !is null && inv.getItemsCount() > 0)
		return false;

	const string name = blob.getName();
	return name == "zchicken" || name == "catto" ||
		name == "skeleton" || name == "zombie" ||
		name == "plantzombie" || name == "bloodzombie" ||
		name == "evilzombie" || name == "zombieknight";
}

CBlob @ZGFindWeakHordeMob(const string &in incomingName)
{
	const int incomingPower = ZGHordePower(incomingName);
	if (incomingPower <= 1)
		return null;

	CBlob @[] horde;
	getBlobsByTag("zombie", @horde);

	CBlob @best;
	int bestPower = incomingPower;
	f32 bestDistance = -1.0f;
	for (uint i = 0; i < horde.length; ++i)
	{
		CBlob @candidate = horde[i];
		if (!ZGIsReplaceableHordeMob(candidate))
			continue;

		const int power = ZGHordePower(candidate.getName());
		if (power <= 0 || power >= incomingPower)
			continue;

		// Avoid visibly deleting creatures at an active defense. Prefer
		// the lowest rank, then the furthest candidate from any player.
		f32 nearestPlayer = 1000000.0f;
		for (uint j = 0; j < getPlayersCount(); ++j)
		{
			CPlayer @player = getPlayer(j);
			if (player is null)
				continue;
			CBlob @body = player.getBlob();
			if (body is null || body.hasTag("dead"))
				continue;
			const f32 distance = (candidate.getPosition() - body.getPosition()).Length();
			if (distance < nearestPlayer)
				nearestPlayer = distance;
		}
		if (nearestPlayer < ZG_HORDE_SAFE_REPLACEMENT_DISTANCE)
			continue;

		if (power < bestPower || (power == bestPower && nearestPlayer > bestDistance))
		{
			@best = candidate;
			bestPower = power;
			bestDistance = nearestPlayer;
		}
	}
	return best;
}

bool ZGCanReplaceHordeMob(CRules @rules, const bool bossWave)
{
	if (!isServer() || rules is null || !rules.get_bool("horde_replacements"))
		return false;

	const u32 interval = bossWave ?
		ZG_HORDE_BOSS_REPLACEMENT_INTERVAL :
		ZG_HORDE_REGULAR_REPLACEMENT_INTERVAL;
	return getGameTime() - rules.get_u32("zg_last_horde_replacement") >= interval;
}

void ZGRetireHordeMob(CRules @rules, CBlob @victim)
{
	if (!isServer() || rules is null || victim is null)
		return;

	// No combat hit: this must not count as a player kill or award loot.
	victim.Tag("zg_horde_retired");
	victim.server_Die();
	rules.set_u32("zg_last_horde_replacement", getGameTime());
}
