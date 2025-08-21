// ArcherShop.as

#include "CTFShopCommon.as";
#include "CheckSpam.as";
#include "Descriptions.as";
#include "Requirements.as";
#include "ShopCommon.as";

void onInit(CBlob @ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-50); // background
	this.getShape().getConsts().mapCollisions = false;

	// load config
	if (getRules().exists("ctf_costs_config"))
	{
		cost_config_file = getRules().get_string("ctf_costs_config");
	}

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(4, 1));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	// CLASS
	this.set_Vec2f("class offset", Vec2f(-6, 0));
	this.set_string("required class", "pyromancer");
	{
		ShopItem @s = addShopItem(this, "Beer", "$beer$", "beer", "Gotta unwind from the zombies!", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 300);
	}
	{
		ShopItem @s = addShopItem(this, "Vodka", "$vodka$", "vodka", "A nice drink for the fire lovers.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 300);
	}
	{
		ShopItem @s = addShopItem(this, "Molotov", "$molotov$", "molotov", "Burn piles of the dead.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 100);
	}
}

void GetButtonsFor(CBlob @ this, CBlob @caller)
{
	u8 kek = caller.getTeamNum();
	if (kek == 0)
	{
		if (caller.getConfig() == this.get_string("required class"))
		{
			this.set_Vec2f("shop offset", Vec2f_zero);
		}
		else
		{
			this.set_Vec2f("shop offset", Vec2f(6, 0));
		}
		this.set_bool("shop available", this.isOverlapping(caller));
	}
}

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
	}
}