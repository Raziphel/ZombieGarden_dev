// Genreic building

#include "CheckSpam.as"
#include "Costs.as"
#include "Descriptions.as"
#include "GenericButtonCommon.as"
#include "Requirements.as"
#include "ShopCommon.as"
#include "TeamIconToken.as"


// are builders the only ones that can finish construction?
const bool builder_only = false;

void onInit(CBlob @ this)
{
	// AddIconToken("$stonequarry$", "../Mods/Entities/Shops/CTFShops/Quarry/Quarry.png", Vec2f(40, 24), 4);
	this.set_TileType("background tile", CMap::tile_wood_back);
	// this.getSprite().getConsts().accurateLighting = true;

	ShopMadeItem @onMadeItem = @onShopMadeItem;
	this.set("onShopMadeItem handle", @onMadeItem);

	this.getSprite().SetZ(-50); // background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("has window");

	// INIT COSTS
	InitCosts();

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(6, 8));
	this.set_string("shop description", "Construct");
	this.set_u8("shop icon", 12);

	this.Tag(SHOP_AUTOCLOSE);

	int team_num = this.getTeamNum();

	{
		ShopItem @s = addShopItem(this, "Dormitory", "$dorm$", "dorm", "Heal yourself and care for migrants.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 25);
		// AddRequirement( s.requirements, "blob", "migrantbot", "Migrant", 1);
	}
	{
		ShopItem @s = addShopItem(this, "Forge", "$forge$", "forge", "Smelt your ores into bars.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 200);
		AddRequirement(s.requirements, "blob", "mat_coal", "Coal", 200);
	}
	{
		ShopItem @s = addShopItem(this, "Trader Shop", "$tradershop$", "tradershop", "Exchange gold or buy paraphernalia.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
	}
	{
		ShopItem @s = addShopItem(this, "Builder Shop", "$buildershop$", "buildershop", "Craft and buy important gadgets or switch to Builder here.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
	}
	{
		ShopItem @s = addShopItem(this, "Knight Shop", "$knightshop$", "knightshop", "Buy bombs or switch to Knight here.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
	}
	{
		ShopItem @s = addShopItem(this, "Archer Shop", "$archershop$", "archershop", "Buy arrows or switch to Archer here.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
	}
	{
		ShopItem @s = addShopItem(this, "Priest's Shop", "$priestshop$", "priestshop", "Buy orbs or switch to Priest here.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
	}
	{
		ShopItem @s = addShopItem(this, "Dragoon Shop", "$dragoonshop$", "dragoonshop", "Become a Dragoon!");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingots", 100);
		AddRequirement(s.requirements, "blob", "dragoonwings", "Dragoon Wings", 2);
	}
	{
		ShopItem @s = addShopItem(this, "Pyro Shop", "$pyroshop$", "pyroshop", "Become a Pyromancer!");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100);
		AddRequirement(s.requirements, "blob", "firesoul", "Fire Soul", 2);
	}
	{
		ShopItem @s = addShopItem(this, "Crossbow Shop", "$crossbowshop$", "crossbowshop", "Become a Crossbow man!");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingots", 100);
		AddRequirement(s.requirements, "blob", "crossbow_item", "Crossbow", 2);
	}
	{
		ShopItem @s = addShopItem(this, "Wizard Shop", "$wizardshop$", "wizardshop", "Become a Wizard! (Harry)");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100);
		AddRequirement(s.requirements, "blob", "wizardstaff", "wizardstaff", 2);
	}
	{
		ShopItem @s = addShopItem(this, "Transport Tunnel", "$tunnel$", "tunnel", "Use them for fast travel.");
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
	}
	{
		ShopItem @s = addShopItem(this, "Storage", "$storage$", "storage", "Save materials.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
	}
	{
		ShopItem @s = addShopItem(this, "Vehicle Shop", "$vehicleshop$", "vehicleshop", "Tonky tonks.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 50);
	}
	{
		ShopItem @s = addShopItem(this, "Defense Shop", "$defenseshop$", "defenseshop", "Buy advanced weaponcraft.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 50);
	}
}

void GetButtonsFor(CBlob @ this, CBlob @caller)
{
	if (!canSeeButtons(this, caller))
		return;

	if (this.isOverlapping(caller))
		this.set_bool("shop available", !builder_only || caller.getName() == "builder");
	else
		this.set_bool("shop available", false);
}

void onShopMadeItem(CBitStream @params)
{
	if (!isServer())
		return;

	u16 this_id, caller_id, item_id;
	string name;

	if (!params.saferead_u16(this_id) || !params.saferead_u16(caller_id) || !params.saferead_u16(item_id) || !params.saferead_string(name))
	{
		return;
	}

	CBlob @ this = getBlobByNetworkID(this_id);
	if (this is null)
		return;

	CBlob @caller = getBlobByNetworkID(caller_id);
	if (caller is null)
		return;

	CBlob @item = getBlobByNetworkID(item_id);
	if (item is null)
		return;

	this.Tag("shop disabled"); // no double-builds
	this.Sync("shop disabled", true);

	this.server_Die();

	// open factory upgrade menu immediately
	if (item.getName() == "factory")
	{
		CBitStream factoryParams;
		factoryParams.write_netid(caller.getNetworkID());
		item.SendCommand(item.getCommandID("upgrade factory menu"), factoryParams); // NOT SANITIZED; TTH
	}
}

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item client") && isClient())
	{
		u16 this_id, caller_id, item_id;
		string name;

		if (!params.saferead_u16(this_id) || !params.saferead_u16(caller_id) || !params.saferead_u16(item_id) || !params.saferead_string(name))
		{
			return;
		}

		CBlob @caller = getBlobByNetworkID(caller_id);
		CBlob @item = getBlobByNetworkID(item_id);

		if (item !is null && caller !is null)
		{
			this.getSprite().PlaySound("/Construct.ogg");
			this.getSprite().getVars().gibbed = true;
			caller.ClearMenus();
		}
	}
}
