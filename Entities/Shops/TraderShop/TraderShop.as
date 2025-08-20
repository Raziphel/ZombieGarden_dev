// Scripts by Diprog, sprite by AsuMagic. If you want to copy/change it and upload to your server ask creators of this file. You can find them at KAG forum.

#include "Requirements.as"
#include "ShopCommon.as";
#include "CheckSpam.as";

void onInit( CBlob@ this )
{	 
	this.set_TileType("background tile", CMap::tile_wood_back);
	this.SetLight(true);
	this.SetLightRadius(64.0f );
	//this.getSprite().getConsts().accurateLighting = true;
	

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(5,4));
	this.set_string("shop description", "Exchange materials and buy stuff");
	this.set_u8("shop icon", 25);
	
	{	 
		ShopItem@ s = addShopItem( this, "Wood", "$mat_wood$", "mat_wood", "Exchange 25 Gold for 250 Wood", true );
		AddRequirement( s.requirements, "blob", "mat_gold", "Gold", 25 );
	}
	{
		ShopItem@ s = addShopItem( this, "Stone", "$mat_stone$", "mat_stone", "Exchange 50 Gold for 250 Stone", true );
		AddRequirement( s.requirements, "blob", "mat_gold", "Gold", 50 );
	}
	{
		ShopItem@ s = addShopItem( this, "Diving Helmet", "$divinghelmet$", "divinghelmet", "A helmet specially made for underwater exploring.", true );
		AddRequirement( s.requirements, "coin", "", "Coins", 100 );
		AddRequirement( s.requirements, "blob", "mat_steelingot", "Steel Ingot", 10 );
	}
	{	 
		ShopItem@ s = addShopItem( this, "Friendly Shark", "$shark$", "fshark", "It eats the apocalypse.", false, true );
		s.crate_icon = 22;
		AddRequirement( s.requirements, "coin", "", "Coins", 500 );
		AddRequirement( s.requirements, "blob", "mat_gold", "Gold", 75 );
	}
	{
		ShopItem@ s = addShopItem( this, "Mage", "$mage$", "mage", "Hire a Mage who will help you.", false);
		AddRequirement( s.requirements, "coin", "", "Coins", 100 );
		AddRequirement( s.requirements, "blob", "mat_gold", "Gold", 10 );
		AddRequirement(s.requirements, "blob", "migrantbot", "Migrant", 1);
	}
	{
        ShopItem@ s = addShopItem( this, "Random Chest", "$chest$", "randomChest", "Buy your own chests!", true);
        AddRequirement( s.requirements, "blob", "soulshard", "Soul Shards", 3 );
	}
	{
		ShopItem@ s = addShopItem(this, "Beer", "$beer$", "beer", "Gotta unwind from killing zombies!", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 75);
	}
	{
		ShopItem@ s = addShopItem(this, "Vodka", "$vodka$", "vodka", "Are you sure!?", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 250);
	}
	{
		ShopItem@ s = addShopItem(this, "Molotov", "$molotov$", "molotov", "Burn piles of the dead.  (Cheaper for pyros)", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 300);
	}
	{
		ShopItem@ s = addShopItem( this, "Blue Lantern", "$bluelantern$", "bluelantern", "A lantern with a bigger light radius but with a dim ilumination.", true );
		AddRequirement( s.requirements, "coin", "", "Coins", 200 );
	}
	/*
	{
		ShopItem@ s = addShopItem( this, "Gold Drill", "$golddrill$", "golddrill", "An improved drill.", true );
		AddRequirement( s.requirements, "coin", "", "Coins", 50 );
	}
	*/

}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	u8 kek = caller.getTeamNum();	
	if (kek == 0)
	{
		this.set_bool("shop available", this.isOverlapping(caller) /*&& caller.getName() == "builder"*/ );
	}
}
								   
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound( "/ChaChing.ogg" );
		
		bool isServer = (getNet().isServer());
			
		u16 caller, item;
		
		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;
		
		CBlob@ blob = getBlobByNetworkID( caller );
		CBlob@ tree;
		Vec2f pos = this.getPosition();
		
		string name = params.read_string();
		
		{
			if(name == "randomChest")
			{
				if (isServer)
				{
					server_CreateBlob("chest", this.getTeamNum(), this.getPosition());
				}			
			}		
		}
	}
}

