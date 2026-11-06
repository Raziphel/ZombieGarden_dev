// spawn resources

#include "Structs.as";
#include "RulesCore.as";

const u32 materials_wait = 20;		  // seconds between free mats
const u32 materials_wait_warmup = 40; // seconds between free mats

// property
const string SPAWN_ITEMS_TIMER = "SpawnItems:";

string base_name()
{
	return "tent";
}

bool SetMaterials(CBlob @blob, const string&in name, const int quantity)
{
	if (!isServer() || blob is null || quantity <= 0)
		return false;

	CInventory @inv = blob.getInventory();
	if (inv is null)
		return false;

	// already got them?
	if (inv.isInInventory(name, quantity))
		return false;

	// otherwise...
	inv.server_RemoveItems(name, quantity); // shred any old ones

	CBlob @mat = server_CreateBlob(name);
	if (mat !is null)
	{
		mat.Tag("do not set materials");
		mat.server_SetQuantity(quantity);
		if (!blob.server_PutInInventory(mat))
		{
			mat.setPosition(blob.getPosition());
		}
	}

	return true;
}

bool GiveSpawnResources(CRules @ this, CBlob @blob, CPlayer @player, CTFPlayerInfo @info)
{
	bool ret = false;

	if (blob.getName() == "builder")
	{
		if (this.isWarmup())
		{
			ret = SetMaterials(blob, "mat_wood", 300) || ret;
			ret = SetMaterials(blob, "mat_stone", 100) || ret;
		}
		else
		{
			ret = SetMaterials(blob, "mat_wood", 100) || ret;
			ret = SetMaterials(blob, "mat_stone", 30) || ret;
		}

		if (ret)
		{
			info.items_collected |= ItemFlag::Builder;
		}
	}
	else if (blob.getName() == "archer" || blob.getName() == "crossbow" || blob.getName() == "undeadarcher")
	{
		ret = SetMaterials(blob, "mat_arrows", 60) || ret;

		if (ret)
		{
			info.items_collected |= ItemFlag::Archer;
		}
	}
	else if (blob.getName() == "knight")
	{
		if (ret)
		{
			info.items_collected |= ItemFlag::Knight;
		}
	}
	else if (blob.getName() == "priest" || blob.getName() == "undeadmystic")
	{
		ret = SetMaterials(blob, "mat_orbs", 30) || ret;

		if (ret)
		{
			info.items_collected |= ItemFlag::Wiz;
		}
	}
	else if (blob.getName() == "undeadbuilder")
	{
		ret = SetMaterials(blob, "mat_wood", 150) || ret;
		ret = SetMaterials(blob, "mat_stone", 200) || ret;

		if (ret)
		{
			info.items_collected |= ItemFlag::Nec;
		}
	}
	else if (blob.getName() == "burd")
	{
		ret = SetMaterials(blob, "mat_wood", 500) || ret;
		ret = SetMaterials(blob, "mat_stone", 250) || ret;
		ret = SetMaterials(blob, "mat_gold", 100) || ret;
		ret = SetMaterials(blob, "scrollchicken", 1) || ret;

		if (ret)
		{
			info.items_collected |= ItemFlag::Burd;
		}
	}
	else if (blob.getName() == "assassin" || blob.getName() == "dragoon")
	{
		ret = SetMaterials(blob, "bomb_satchel", 1) || ret;

		if (ret)
		{
			info.items_collected |= ItemFlag::Fighter;
		}
	}

	return ret;
}

// when the player is set, give materials if possible
void onSetPlayer(CRules @ this, CBlob @blob, CPlayer @player)
{
	if (!getNet().isServer())
		return;

	if (blob !is null && player !is null)
	{
		RulesCore @core;
		this.get("core", @core);
		if (core !is null)
		{
			doGiveSpawnMats(this, player, blob, core);
		}
	}
}

// when player dies, unset archer flag so he can get arrows if he really sucks :)
// give a guy a break :)
void onPlayerDie(CRules @ this, CPlayer @victim, CPlayer @attacker, u8 customData)
{
	if (victim !is null)
	{
		RulesCore @core;
		this.get("core", @core);
		if (core !is null)
		{
			CTFPlayerInfo @info = cast<CTFPlayerInfo @>(core.getInfoFromPlayer(victim));
			if (info !is null)
			{
				info.items_collected &= ~ItemFlag::Archer;
			}
		}
	}
}

bool canGetSpawnmats(CRules @ this, CPlayer @p, RulesCore @core)
{
	if (p is null || core is null)
		return false;

	CTFPlayerInfo @info = cast<CTFPlayerInfo @>(core.getInfoFromPlayer(p));
	CBlob @b = p.getBlob();
	if (info is null || b is null || b.hasTag("dead"))
		return false;

	const s32 next_items = getSpawnTimer(this, p);
	const s32 gametime = getGameTime();

	if (gametime > next_items ||										// timer expired
		gametime < next_items - materials_wait * getTicksASecond() * 4) // residual prop
	{
		info.items_collected = 0;										// reset available class items
		return true;
	}
	else																// trying to get new class items, give a guy a break
	{
		u32 items = info.items_collected;
		u32 flag = 0;

		const string name = b.getName();
		if (name == "builder")
			flag = ItemFlag::Builder;
		else if (name == "archer" || name == "crossbow" || name == "undeadarcher")
			flag = ItemFlag::Archer;
		else if (name == "knight")
			flag = ItemFlag::Knight;
		else if (name == "priest" || name == "undeadmystic")
			flag = ItemFlag::Wiz;
		else if (name == "undeadbuilder")
			flag = ItemFlag::Nec;
		else if (name == "burd")
			flag = ItemFlag::Burd;
		else if (name == "assassin" || name == "dragoon")
			flag = ItemFlag::Fighter;

		// Check the requested class flag, not an implicit comparison
		// against zero. Unrecognized classes have no free supply grant.
		if (flag != 0 && (info.items_collected & flag) == 0)
			return true;
	}

	return false;
}

string getSpawnTimerPropertyName(CPlayer @p)
{
	return SPAWN_ITEMS_TIMER + p.getUsername();
}

s32 getSpawnTimer(CRules @ this, CPlayer @p)
{
	string property = getSpawnTimerPropertyName(p);
	if (this.exists(property))
		return this.get_s32(property);
	else
		return 0;
}

void SetSpawnTimer(CRules @ this, CPlayer @p, s32 time)
{
	string property = getSpawnTimerPropertyName(p);
	this.set_s32(property, time);
	this.SyncToPlayer(property, p);
}

// takes into account and sets the limiting timer
// prevents dying over and over, and allows getting more mats throughout the game
void doGiveSpawnMats(CRules @ this, CPlayer @p, CBlob @b, RulesCore @core)
{
	if (!isServer() || p is null || b is null || core is null)
		return;

	if (canGetSpawnmats(this, p, core))
	{
		s32 gametime = getGameTime();

		CTFPlayerInfo @info = cast<CTFPlayerInfo @>(core.getInfoFromPlayer(p));
		if (info is null)
			return;

		bool gotmats = GiveSpawnResources(this, b, p, info);
		if (gotmats)
		{
			SetSpawnTimer(this, p, gametime + (this.isWarmup() ? materials_wait_warmup : materials_wait) * getTicksASecond());
		}
	}
}

// normal hooks

void Reset(CRules @ this)
{
	if (!isServer())
		return;

	// restart everyone's timers
	for (uint i = 0; i < getPlayersCount(); ++i)
	{
		CPlayer @player = getPlayer(i);
		if (player !is null)
			SetSpawnTimer(this, player, materials_wait_warmup);
	}
}

void onRestart(CRules @ this)
{
	Reset(this);
}

void onInit(CRules @ this)
{
	Reset(this);
}

void onTick(CRules @ this)
{
	if (!getNet().isServer())
		return;

	s32 gametime = getGameTime();

	if ((gametime % 31) != 5)
		return;

	RulesCore @core;
	this.get("core", @core);
	if (core !is null)
	{

		CBlob @[] spots;
		getBlobsByName(base_name(), @spots);
		getBlobsByName("buildershop", @spots);
		getBlobsByName("knightshop", @spots);
		getBlobsByName("archershop", @spots);
		getBlobsByName("wshop", @spots);
		for (uint step = 0; step < spots.length; ++step)
		{
			CBlob @spot = spots[step];
			CBlob @[] overlapping;
			if (spot !is null && spot.getOverlapping(overlapping))
			{
				string name = spot.getName();
				bool isShop = (name.find("shop") != -1);
				for (uint o_step = 0; o_step < overlapping.length; ++o_step)
				{
					CBlob @overlapped = overlapping[o_step];
					if (overlapped !is null && overlapped.hasTag("player"))
					{
						if (!isShop || name.find(overlapped.getName()) != -1)
						{
							CPlayer @p = overlapped.getPlayer();
							if (p !is null)
							{
								doGiveSpawnMats(this, p, overlapped, core);
							}
						}
					}
				}
			}
		}
	}
}

// render gui for the player
void onRender(CRules @ this)
{
	CPlayer @p = getLocalPlayer();
	if (p is null || !p.isMyPlayer())
	{
		return;
	}

	string propname = getSpawnTimerPropertyName(p);
	CBlob @b = p.getBlob();
	if (b !is null && this.exists(propname))
	{
		s32 next_items = this.get_s32(propname);
		if (getGameTime() < next_items - materials_wait * getTicksASecond() * 2)
		{
			this.set_s32(propname, 0); // clear residue
		}
		else if (next_items > getGameTime())
		{
			f32 offset = 140.0f;
			string verb = (b.getName() == "builder" ? "Build" : "Fight");
			if (this.isWarmup())
			{
				verb = "Prepare for Battle";
				offset = 175.0f;
			}
		}
	}
}
