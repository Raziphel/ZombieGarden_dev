// A script by TFlippy

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";

Random traderRandom(Time());

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");

	// getMap().server_SetTile(this.getPosition(), CMap::tile_castle_back);

       AddIconToken("$mat_copperingot$", "../Resources/Material/Materials.png", Vec2f(16, 16), 51);
       AddIconToken("$mat_ironingot$", "../Resources/IronIngot/MaterialIronIngot.png", Vec2f(16, 16), 1);
       AddIconToken("$mat_steelingot$", "../Resources/SteelIngot/MaterialSteelIngot.png", Vec2f(16, 16), 1);
	
	this.set_Vec2f("shop offset", Vec2f(0,1));
	this.set_Vec2f("shop menu size", Vec2f(5, 2));
	this.set_string("shop description", "Forge");
	this.set_u8("shop icon", 15);

	{
		ShopItem@ s = addShopItem(this, "Copper Ingot (10)", "$mat_copperingot$", "mat_copperingot-10", "A soft conductive metal.", true);
		AddRequirement(s.requirements, "blob", "mat_copperore", "Copper Ore", 50);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Iron Ingot (10)", "$mat_ironingot$", "mat_ironingot-10", "A fairly strong metal used to make tools, equipment and such.", true);
		AddRequirement(s.requirements, "blob", "mat_ironore", "Iron Ore", 50);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Steel Ingot (10)", "$mat_steelingot$", "mat_steelingot-10", "Much stronger than iron, but also more expensive.", true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 25);
		AddRequirement(s.requirements, "blob", "mat_coal", "Coal", 25);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Coal (10)", "$mat_coal$", "mat_coal-10", "A black rock that is used for fuel.", true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		s.spawnNothing = true;
	}
    
    CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("CampfireSound.ogg");
		sprite.SetEmitSoundVolume(0.90f);
		sprite.SetEmitSoundSpeed(1.0f);
        sprite.SetEmitSoundPaused(true);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{

	this.set_Vec2f("shop offset", Vec2f(2,0));

	this.set_bool("shop available", this.isOverlapping(caller));
}

void onTick(CBlob @this){
    if(isClient())
    if(getGameTime() >= this.get_u32("time_used")+60){
        this.getSprite().SetAnimation("default");
        this.getSprite().SetEmitSoundPaused(true);
        this.getCurrentScript().tickFrequency = 600;
    }

}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
        if(isClient()){
            this.getSprite().PlaySound("ProduceSound.ogg");
            this.getSprite().PlaySound("BombMake.ogg");
            
            this.getSprite().SetAnimation("active");
            this.getSprite().SetEmitSoundPaused(false);
            this.getCurrentScript().tickFrequency = 1;
            this.set_u32("time_used",getGameTime());
        }

		if (isServer())
		{
			u16 caller, item;

			if (!params.saferead_netid(caller) || !params.saferead_netid(item))
				return;

			string name = params.read_string();

			if (name.findFirst("mat_") != -1 || name.findFirst("ammo_") != -1)
			{
				CBlob@ callerBlob = getBlobByNetworkID(caller);

				if (callerBlob !is null)
				{
					CPlayer@ callerPlayer = callerBlob.getPlayer();
					string[] tokens = name.split("-");

					if (callerPlayer !is null)
					{
						MakeMat(callerBlob, this.getPosition(), tokens[0], parseInt(tokens[1]));

						// CBlob@ mat = server_CreateBlob(tokens[0]);

						// if (mat !is null)
						// {
							// mat.Tag("do not set materials");
							// mat.server_SetQuantity(parseInt(tokens[1]));
							// if (!callerBlob.server_PutInInventory(mat))
							// {
								// mat.setPosition(callerBlob.getPosition());
							// }
						// }
					}
				}
			}
		}
	}
}