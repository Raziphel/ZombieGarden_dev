// Scripts by Diprog, sprite by AsuMagic. If you want to copy/change it and upload to your server ask creators of this file. You can find them at KAG forum.

#include "CheckSpam.as";
#include "Requirements.as"
#include "ShopCommon.as";


void onInit(CBlob @ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);
	this.SetLight(true);
	this.SetLightRadius(64.0f);
	// this.getSprite().getConsts().accurateLighting = true;

	this.getSprite().SetZ(-50); // background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(4, 2));
	this.set_string("shop description", "Exchange materials and buy stuff");
	this.set_u8("shop icon", 25);

	{
		ShopItem @s = addShopItem(this, "Random Chest", "$chest$", "randomChest", "Buy your own chests!", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 1000);
	}
	{
		ShopItem @s = addShopItem(this, "Blue Lantern", "$bluelantern$", "bluelantern", "A lantern with a bigger light radius but with a dim ilumination.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 200);
	}
	{
		ShopItem @s = addShopItem(this, "Diving Helmet", "$divinghelmet$", "divinghelmet", "A helmet specially made for underwater exploring.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 100);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 10);
	}
	{
		ShopItem @s = addShopItem(this, "Molotov", "$molotov$", "molotov", "Burn piles of the dead.  (Cheaper for pyros)", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 100);
	}
	{
		ShopItem @s = addShopItem(this, "Mage", "$mage$", "mage", "Hire a Mage who will help you.", false);
		AddRequirement(s.requirements, "coin", "", "Coins", 200);
		AddRequirement(s.requirements, "blob", "migrantbot", "Migrant", 1);
	}
}

void GetButtonsFor(CBlob @ this, CBlob @caller)
{
	u8 kek = caller.getTeamNum();
	if (kek == 0)
	{
		this.set_bool("shop available", this.isOverlapping(caller) /*&& caller.getName() == "builder"*/);
	}
}

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{

	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");

		bool isServer = (getNet().isServer());

		u16 caller, item;

		if (!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;

		CBlob @blob = getBlobByNetworkID(caller);
		CBlob @tree;
		Vec2f pos = this.getPosition();

		string name = params.read_string();

		{
			if (name == "randomChest")
			{
				if (isServer)
				{
					server_CreateBlob("chest", this.getTeamNum(), this.getPosition());
				}
			}
		}
	}
}
