// Generic building

#include "Requirements.as"
#include "ShopCommon.as";
#include "Descriptions.as";
#include "WARCosts.as";
#include "CheckSpam.as";

//are builders the only ones that can finish construction?
const bool builder_only = false;

void onInit( CBlob@ this )
{	 
	this.set_TileType("background tile", CMap::tile_wood_back);
	//this.getSprite().getConsts().accurateLighting = true;

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(6,8));	
	this.set_string("shop description", "Construct");
	this.set_u8("shop icon", 12);
	
	this.Tag(SHOP_AUTOCLOSE);
	
	
	{
		ShopItem@ s = addShopItem( this, "Dormitory", "$dorm$", "dorm", "Respawn, heal yourself or switch classes." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 50 );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 25 );
		//AddRequirement(s.requirements, "blob", "migrantbot", "Migrant", 1);
	}
	{
		ShopItem@ s = addShopItem( this, "Trader Shop", "$tradershop$", "tradershop", "Exchange gold or buy paraphernalia." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 50 );
	}	
	{
		ShopItem@ s = addShopItem( this, "Builder Shop", "$buildershop$", "buildershop", "Craft and buy important gadgets or switch to Builder here." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_FACTORY );
	}
	{
		ShopItem@ s = addShopItem( this, "Knight Shop", "$knightshop$", "knightshop", "Buy bombs or switch to Knight here." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_FACTORY );
	}	
	{
		ShopItem@ s = addShopItem( this, "Archer Shop", "$archershop$", "archershop", "Buy arrows or switch to Archer here." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_FACTORY );
	}
		{
		ShopItem@ s = addShopItem( this, "Priest's Shop", "$priestshop$", "priestshop", "Buy orbs or switch to Priest here." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_FACTORY );
	}	
	{
		ShopItem@ s = addShopItem( this, "Transport Tunnel", "$tunnel$", "tunnel", "Use them for fast travel." );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 100 );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 50 );
	}	
	{
		ShopItem@ s = addShopItem( this, "Storage", "$storage$", "storage", "Save materials." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 50 );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 100 );
	}
	{
		ShopItem@ s = addShopItem( this, "Vehicle Shop", "$vehicleshop$", "vehicleshop", "Tonky tonks." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 100 );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 50 );
	}
	{
		ShopItem@ s = addShopItem( this, "Defense Shop", "$defenseshop$", "defenseshop", "Buy advanced weaponcraft." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 100 );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 50 );
	}
	{
		ShopItem@ s = addShopItem( this, "Dragoon Shop", "$dragoonshop$", "dragoonshop", "Become a Dragoon!" );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 100 );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 100 );
		AddRequirement( s.requirements, "blob", "mat_steel", "Steel", 100 );
		AddRequirement( s.requirements, "blob", "dragoonwings", "Dragoon Wings", 2 );
	}
	{
		ShopItem@ s = addShopItem( this, "Pyro Shop", "$pyroshop$", "pyroshop", "Become a Pyromancer!" );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 100 );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 100 );
		AddRequirement( s.requirements, "blob", "mat_gold", "Gold", 100 );
		AddRequirement( s.requirements, "blob", "firesoul", "Fire Soul", 2 );
	}
	{
		ShopItem@ s = addShopItem( this, "Crossbow Shop", "$crossbowshop$", "crossbowshop", "Become a Crossbow!" );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 100 );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 100 );
		AddRequirement( s.requirements, "blob", "mat_steel", "Steel", 100 );
		AddRequirement( s.requirements, "blob", "Crossbow", "Crossbow", 2 );
	}
	{
		ShopItem@ s = addShopItem( this, "Wizard Shop", "$wizardshop$", "wizardshop", "Become a Wizard! (Harry)" );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 100 );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 100 );
		AddRequirement( s.requirements, "blob", "mat_gold", "Gold", 100 );
		AddRequirement( s.requirements, "blob", "wizardstaff", "wizardstaff", 2 );
	}
	{
		ShopItem@ s = addShopItem( this, "Chicken Builder Shop", "$minibuildershop$", "minibuildershop", "Taking being a tunnel rat to a new level." );
		AddRequirement( s.requirements, "blob", "mat_wood", "Wood", 100 );
		AddRequirement( s.requirements, "blob", "mat_stone", "Stone", 100 );
		AddRequirement( s.requirements, "blob", "mat_gold", "Gold", 100 );
		AddRequirement( s.requirements, "blob", "chickenhead", "chickenhead", 2 );
	}


}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	if(this.isOverlapping(caller))
		this.set_bool("shop available", !builder_only || caller.getName() == "builder" );
	else
		this.set_bool("shop available", false );
}
								   
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	bool isServer = getNet().isServer();
	if (cmd == this.getCommandID("shop made item"))
	{
		this.Tag("shop disabled"); //no double-builds
		
		CBlob@ caller = getBlobByNetworkID( params.read_netid() );
		CBlob@ item = getBlobByNetworkID( params.read_netid() );
		if (item !is null && caller !is null)
		{
			this.getSprite().PlaySound("/Construct.ogg" ); 
			this.getSprite().getVars().gibbed = true;
			this.server_Die();

			// open factory upgrade menu immediately
			if (item.getName() == "factory")
			{
				CBitStream factoryParams;
				factoryParams.write_netid( caller.getNetworkID() );
				item.SendCommand( item.getCommandID("upgrade factory menu"), factoryParams );
			}
		}
	}
}
