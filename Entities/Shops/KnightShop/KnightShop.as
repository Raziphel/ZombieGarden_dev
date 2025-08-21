﻿// Knight Workshop

#include "CheckSpam.as"
#include "Costs.as"
#include "Descriptions.as"
#include "GenericButtonCommon.as"
#include "Requirements.as"
#include "ShopCommon.as"
#include "TeamIconToken.as"


void onInit(CBlob @ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-50); // background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("has window");

	// INIT COSTS
	InitCosts();

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(4, 1));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	// CLASS
	this.set_Vec2f("class offset", Vec2f(-6, 0));
	this.set_string("required class", "knight");

	int team_num = this.getTeamNum();

	{
		ShopItem @s = addShopItem(this, "Bomb", "$bomb$", "mat_bombs", descriptions[1], true);
		AddRequirement(s.requirements, "coin", "", "Coins", 25);
	}
	{
		ShopItem @s = addShopItem(this, "Water Bomb", "$waterbomb$", "mat_waterbombs", descriptions[52], true);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
	}
	{
		ShopItem @s = addShopItem(this, "Mine", "$mine$", "mine", descriptions[20], false);
		AddRequirement(s.requirements, "coin", "", "Coins", 75);
	}
	{
		ShopItem @s = addShopItem(this, "Keg", "$keg$", "keg", descriptions[4], false);
		AddRequirement(s.requirements, "coin", "", "Coins", 200);
	}
}

void GetButtonsFor(CBlob @ this, CBlob @caller)
{
	if (!canSeeButtons(this, caller))
		return;

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

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item client") && isClient())
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
	}
}
