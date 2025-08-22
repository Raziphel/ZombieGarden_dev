// Builder Workshop

#include "Requirements.as"
#include "ShopCommon.as";
#include "WARCosts.as";
#include "CheckSpam.as";

void onInit( CBlob@ this )
{	 
	this.set_TileType("background tile", CMap::tile_wood_back);
	//this.getSprite().getConsts().accurateLighting = true;
	
	AddIconToken("$scrollcarnage$", "ScrollCarnage.png", Vec2f(16,13), 1);
	AddIconToken("$scrolldrought$", "ScrollDrought.png", Vec2f(16,16), 1);
	AddIconToken("$scrollheal$", "ScrollHeal.png", Vec2f(16,16), 1);
	AddIconToken("$scrollmidas$", "ScrollOfMidas.png", Vec2f(16,16), 1);
	AddIconToken("$scrollreinforce$", "ScrollReinforce.png", Vec2f(16,16), 1);
	AddIconToken("$scrolltaming$", "ScrollMeteor.png", Vec2f(16,16), 1);

	//unused scrolls
	// AddIconToken("$scrollmeteor$", "ScrollMeteor.png", Vec2f(16,16), 1);
	// AddIconToken("$scrollshark$", "ScrollShark.png", Vec2f(16,16), 1);
	// AddIconToken("$scrollreturn$", "ScrollReturn.png", Vec2f(16,16), 1);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(3,3));	
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	{
		ShopItem@ s = addShopItem(this, "Scroll of Drought", "$scrolldrought$", "scrolldrought", "Once used, it will evaporate nearby water.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 100);
	}
	{
		ShopItem@ s = addShopItem(this, "Scroll of Midas", "$scrollmidas$", "scrollmidas", "Once used, it will turn nearby stone into gold.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 250);
	}
	{
		ShopItem@ s = addShopItem(this, "Scroll of Reinforcement", "$scrollreinforce$", "scrollreinforce", "Once used, it will turn nearby stone into thickstone.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 250);
	}
	{
		ShopItem@ s = addShopItem(this, "Scroll of Shark", "$scrollfshark$", "scrollfshark", "Once used, it will spawn a friendly shark to help kill zombies.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 250);
	}
	{
		ShopItem@ s = addShopItem(this, "Scroll of Meteor", "$scrollmeteor$", "scrollmeteor", "Once used, it will spawn a meteor to smite zombies.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 250);
	}
	{
		ShopItem@ s = addShopItem(this, "Scroll of Elemental", "$scrollelemental$", "scrollelemental", "Once used, it will spawn a friendly elementals to help kill zombies.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 250);
	}
	{
		ShopItem@ s = addShopItem(this, "Scroll of 2 weeks", "$scroll2weeks$", "scroll2weeks", "Once used, skip 2 weeks into the future.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);
	}
	{	 
		ShopItem@ s = addShopItem(this, "Scroll of Carnage", "$scrollcarnage$", "scrollcarnage", "Once used, it will damage all nearby zombies.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 1500);
	}
	{
		ShopItem@ s = addShopItem(this, "The Undead Curse", "$scrollundead$", "scrollundead", "Once used, it will convert you to the zombie team.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 5000);
	}
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{

	this.set_bool("shop available", this.isOverlapping(caller) /*&& caller.getName() == "builder"*/ );
}
								   
void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound( "/ChaChing.ogg" );
	}
}
			