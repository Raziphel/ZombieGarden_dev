// A script by TFlippy

#include "CTFShopCommon.as";
#include "CheckSpam.as";
#include "Descriptions.as";
#include "MakeMat.as";
#include "Requirements.as";
#include "ShopCommon.as";


Random traderRandom(Time());

void onInit(CBlob @ this)
{
	// Base Shop.as invokes this callback only after it has checked the
	// player's distance and charged the recipe requirements on the server.
	ShopMadeItem @onMadeItem = @onShopMadeItem;
	this.set("onShopMadeItem handle", @onMadeItem);

	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getSprite().SetZ(-50); // background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");

	// getMap().server_SetTile(this.getPosition(), CMap::tile_castle_back);

        AddIconToken("$mat_copperingot$", "Entities/Resources/Material/Materials.png", Vec2f(16, 16), 41);
        AddIconToken("$mat_ironingot$", "Entities/Resources/IronIngot/MaterialIronIngot.png", Vec2f(16, 16), 3);
        AddIconToken("$mat_steelingot$", "Entities/Resources/SteelIngot/MaterialSteelIngot.png", Vec2f(16, 16), 3);
        AddIconToken("$mat_coal$", "Entities/Resources/Coal/MaterialCoal.png", Vec2f(16, 16), 24);

	this.set_Vec2f("shop offset", Vec2f(2, 0));
	this.set_Vec2f("shop menu size", Vec2f(5, 2));
	this.set_string("shop description", "Forge");
	this.set_u8("shop icon", 15);

	{
		ShopItem @s = addShopItem(this, "Copper Ingot (10)", "$mat_copperingot$", "mat_copperingot-10", "A soft conductive metal.", true);
		AddRequirement(s.requirements, "blob", "mat_copperore", "Copper Ore", 50);
		s.spawnNothing = true;
	}
	{
		ShopItem @s = addShopItem(this, "Iron Ingot (10)", "$mat_ironingot$", "mat_ironingot-10", "A fairly strong metal used to make tools, equipment and such.", true);
		AddRequirement(s.requirements, "blob", "mat_ironore", "Iron Ore", 50);
		s.spawnNothing = true;
	}
	{
		ShopItem @s = addShopItem(this, "Steel Ingot (10)", "$mat_steelingot$", "mat_steelingot-10", "Much stronger than iron, but also more expensive.", true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 25);
		AddRequirement(s.requirements, "blob", "mat_coal", "Coal", 25);
		s.spawnNothing = true;
	}
	{
		ShopItem @s = addShopItem(this, "Coal (10)", "$mat_coal$", "mat_coal-10", "A black rock that is used for fuel.", true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		s.spawnNothing = true;
	}

	CSprite @sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("CampfireSound.ogg");
		sprite.SetEmitSoundVolume(0.90f);
		sprite.SetEmitSoundSpeed(1.0f);
		sprite.SetEmitSoundPaused(true);
	}
}

// Leave "shop available" global. KAG's Shop.as handles each caller's
// button radius and validates purchase distance on the server. Flipping a
// shared availability flag in GetButtonsFor hid the shop from other players.

void onTick(CBlob @ this)
{
	if (isClient())
		if (getGameTime() >= this.get_u32("time_used") + 60)
		{
			this.getSprite().SetAnimation("default");
			this.getSprite().SetEmitSoundPaused(true);
			this.getCurrentScript().tickFrequency = 600;
		}
}

// The base shop's "shop buy" command pays for recipes and calls this
// registered callback. Never mint resources from a client-sent command.
void onShopMadeItem(CBitStream @params)
{
	if (!isServer() || params is null)
		return;

	u16 shopID, callerID, itemID;
	string recipe;
	if (!params.saferead_u16(shopID) ||
		!params.saferead_u16(callerID) ||
		!params.saferead_u16(itemID) ||
		!params.saferead_string(recipe))
		return;

	CBlob @shop = getBlobByNetworkID(shopID);
	CBlob @caller = getBlobByNetworkID(callerID);
	CPlayer @activeBuyer = getNet().getActiveCommandPlayer();
	if (shop is null || shop.getName() != "forge" || caller is null ||
		activeBuyer is null || activeBuyer.getBlob() !is caller)
		return;

	// Keep the output strictly aligned with the four paid forge recipes.
	string output = "";
	if (recipe == "mat_copperingot-10")
		output = "mat_copperingot";
	else if (recipe == "mat_ironingot-10")
		output = "mat_ironingot";
	else if (recipe == "mat_steelingot-10")
		output = "mat_steelingot";
	else if (recipe == "mat_coal-10")
		output = "mat_coal";
	else
		return;

	MakeMat(caller, shop.getPosition(), output, 10);
}

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{
	// This command is emitted by Shop.as after a successful server purchase.
	// It is for presentation only, never resource creation.
	if (cmd == this.getCommandID("shop made item client") && isClient())
	{
		CSprite @sprite = this.getSprite();
		if (sprite is null)
			return;

		sprite.PlaySound("ProduceSound.ogg");
		sprite.PlaySound("BombMake.ogg");
		sprite.SetAnimation("active");
		sprite.SetEmitSoundPaused(false);
		this.getCurrentScript().tickFrequency = 1;
		this.set_u32("time_used", getGameTime());
	}
}
