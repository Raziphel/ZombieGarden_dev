// SlotMachine

#include "Requirements.as"
// #include "ShopCommon.as";
// #include "Descriptions.as";
#include "MakeScroll.as";
#include "WARCosts.as";


void onInit(CBlob @ this)
{
	this.addCommandID("shop menu");
	this.set_string("produce sound", "/PopIn");
	/*
		{
			addSeedItem( this, "tree_pine", "Pine tree seed", 8, 3 );
		}
		{
			addSeedItem( this, "tree_bushy", "Oak tree seed", 8, 3 );
		}
		{
			addSeedItem( this, "grain_plant", "Grain plant seed", 8, 3 );
		}
		{
			addSeedItem( this, "bush", "Bush seed", 8, 3 );
		}
		{
			addSeedItem( this, "flowers", "Flowers seed", 8, 3 );
		}
	*/
	this.set_TileType("background tile", CMap::tile_wood_back);
	this.getSprite().getConsts().accurateLighting = true;

	this.getSprite().SetZ(-50); // background
	this.getShape().getConsts().mapCollisions = false;

	// this.Tag("inventory access");
	// this.set_string("autograb blob", "seed");
	// this.inventoryButtonPos = Vec2f(0.0f, -24.0f);
	this.set_Vec2f("shop offset", Vec2f(0, 8));
	this.set_Vec2f("shop menu size", Vec2f(6, 1));
	this.set_string("shop description", "Play");
	this.set_u8("shop icon", 25);
	this.set_string("required class", "builder");
}

// The server rolls the reels when it charges for a spin. Clients never
// submit winning symbols or choose the random seed.
const u32 SLOT_SPIN_TICKS = 64;
const int SLOT_SPIN_COST = 10;

void GetButtonsFor(CBlob @ this, CBlob @caller)
{
	if (caller is null || this.get_bool("spinning"))
		return;

	CBitStream params;
	CButton @button = caller.CreateGenericButton(
		this.get_u8("shop icon"),
		this.get_Vec2f("shop offset"),
		this,
		this.getCommandID("shop menu"),
		this.get_string("shop description"),
		params);
	if (button !is null)
		button.enableRadius = 32;
}

void AwardSlotResult(CBlob @this)
{
	u8 r1 = this.get_u8("slot_r1");
	u8 r2 = this.get_u8("slot_r2");
	u8 r3 = this.get_u8("slot_r3");

	// Wild symbols may substitute for another matching symbol.
	if (r1 == 6 || r2 == 6 || r3 == 6)
	{
		if (r1 == 6 && r2 == r1 && r3 != 6)
		{
			r1 = r3;
			r2 = r3;
		}
		else if (r2 == 6 && r3 == r2 && r1 != 6)
		{
			r2 = r1;
			r3 = r1;
		}
		else if (r1 == 6 && r3 == r1 && r2 != 6)
		{
			r1 = r2;
			r3 = r2;
		}
		else if (r1 == 6 && r3 == r2 && r2 != 6)
			r1 = r2;
		else if (r2 == 6 && r1 == r3 && r1 != 6)
			r2 = r1;
		else if (r3 == 6 && r1 == r2 && r2 != 6)
			r3 = r2;
		else if (r1 == 0 && r2 == 6)
			r1 = r2;
	}

	if (r1 == 0 && r1 == r2 && r1 == r3)
	{
		CBlob @buyer = getBlobByNetworkID(this.get_netid("slot_buyer"));
		if (buyer !is null && buyer.getPlayer() !is null)
			buyer.server_SetHealth(buyer.getInitialHealth() + 1.5f);
	}
	else if (r1 == 0 && r1 == r2)
		server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 30);
	else if (r1 == 1 && r1 == r2 && r1 == r3)
		server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 50);
	else if (r1 == 2 && r1 == r2 && r1 == r3)
		server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 100);
	else if (r1 == 3 && r1 == r2 && r1 == r3)
		server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 200);
	else if (r1 == 4 && r1 == r2 && r1 == r3)
		server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 500);
	else if (r1 == 5 && r1 == r2 && r1 == r3)
		server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 1000);
	else if (r1 == 6 && r1 == r2 && r1 == r3)
		server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 5000);
	else if (r1 == 7 && r1 == r2 && r1 == r3)
		server_MakePredefinedScroll(this.getPosition(), "sdragoon");
	else if (r1 == 0)
		server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 20);
}

void onTick(CBlob @this)
{
	if (!isServer() || !this.get_bool("spinning") ||
		getGameTime() < this.get_u32("slot_spin_end"))
		return;

	// Clear the pending spin before awarding. A duplicated command cannot
	// replay the same rewards and the next buyer can safely use the machine.
	this.set_bool("spinning", false);
	this.set_bool("spin", false);
	this.Sync("spinning", true);
	this.Sync("spin", true);
	AwardSlotResult(this);
}

void onCommand(CBlob @this, u8 cmd, CBitStream @params)
{
	if (cmd != this.getCommandID("shop menu") || !isServer() ||
		this.get_bool("spinning") || this.getHealth() <= 0.0f)
		return;

	// Trust the authenticated command sender, not a client-supplied player
	// network ID or a client-supplied random number.
	CPlayer @player = getNet().getActiveCommandPlayer();
	if (player is null || player.getCoins() < SLOT_SPIN_COST)
		return;

	CBlob @buyer = player.getBlob();
	if (buyer is null || buyer.hasTag("dead") ||
		buyer.getDistanceTo(this) > 32.0f)
		return;

	player.server_setCoins(player.getCoins() - SLOT_SPIN_COST);
	this.set_netid("slot_buyer", buyer.getNetworkID());
	this.set_u8("slot_r1", u8(XORRandom(8)));
	this.set_u8("slot_r2", u8(XORRandom(8)));
	this.set_u8("slot_r3", u8(XORRandom(8)));
	this.set_u32("slot_spin_end", getGameTime() + SLOT_SPIN_TICKS);

	// Animation is cosmetic and receives the authoritative final symbols.
	this.set_u32("spinRand", XORRandom(2147483647));
	this.set_bool("spinning", true);
	this.set_bool("spin", true);
	this.Sync("spinRand", true);
	this.Sync("slot_r1", true);
	this.Sync("slot_r2", true);
	this.Sync("slot_r3", true);
	this.Sync("spinning", true);
	this.Sync("spin", true);
}

// leave a pile of wood	after death
void onDie(CBlob @ this)
{
	if (getNet().isServer())
	{
		CBlob @blob = server_CreateBlob("mat_wood", this.getTeamNum(), this.getPosition());
		if (blob !is null)
		{
			blob.server_SetQuantity(COST_WOOD_NURSERY / 2);
		}
	}
}
