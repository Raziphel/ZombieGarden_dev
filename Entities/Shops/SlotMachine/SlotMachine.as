// SlotMachine

#include "Requirements.as"
// #include "ShopCommon.as";
// #include "Descriptions.as";
#include "MakeScroll.as";
#include "WARCosts.as";


void onInit(CBlob @ this)
{
	this.addCommandID("shop menu");
	this.addCommandID("win");
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

void GetButtonsFor(CBlob @ this, CBlob @caller)
{

	// if (this.isOverlapping(caller))
	if (!this.get_bool("spinning"))
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		params.write_u32(XORRandom(2147483647));
		CButton @button = caller.CreateGenericButton(
			this.get_u8("shop icon"),			 // icon token
			this.get_Vec2f("shop offset"),		 // button offset
			this,								 // button attachment
			this.getCommandID("shop menu"),		 // command id
			this.get_string("shop description"), // description
			params);							 // bit stream

		button.enableRadius = 32;
	}
}

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();

	if (cmd == this.getCommandID("shop menu"))
	{
		u16 callid = params.read_u16();
		CBlob @caller = getBlobByNetworkID(callid);
		CPlayer @player = caller.getPlayer();
		if (player.getCoins() >= 10)
		{
			// build menu for them
			if (this.get_bool("spinning"))
				return;
			u32 spinRand = params.read_u32();
			this.set_bool("spin", true);
			this.set_u32("spinRand", spinRand);
			this.set_u16("callid", callid);
			if (player !is null)
			{
				player.server_setCoins(player.getCoins() - 10);
			}
		}
	}
	if (cmd == this.getCommandID("win"))
	{

		if (isServer)
		{
			u16 callid = params.read_u16();
			u8 r1 = params.read_u8();
			u8 r2 = params.read_u8();
			u8 r3 = params.read_u8();
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
				{
					r1 = r2;
				}
				else if (r2 == 6 && r1 == r3 && r1 != 6)
				{
					r2 = r1;
				}
				else if (r3 == 6 && r1 == r2 && r2 != 6)
				{
					r3 = r2;
				}
				else if (r1 == 0 && r2 == 6)
				{
					r1 = r2;
				}
			}
			if (r1 == 0 && r1 == r2 && r1 == r3)
			{
				CBlob @caller = getBlobByNetworkID(callid);
				caller.server_SetHealth(caller.getInitialHealth() + 1.5f);
			}
			else if (r1 == 0 && r1 == r2)
			{
				server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 30);
			}
			else if (r1 == 1 && r1 == r2 && r1 == r3)
			{
				server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 50);
			}
			else if (r1 == 2 && r1 == r2 && r1 == r3)
			{
				server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 100);
			}
			else if (r1 == 3 && r1 == r2 && r1 == r3)
			{
				server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 200);
			}
			else if (r1 == 4 && r1 == r2 && r1 == r3)
			{
				server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 500);
			}
			else if (r1 == 5 && r1 == r2 && r1 == r3)
			{
				server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 1000);
			}
			else if (r1 == 6 && r1 == r2 && r1 == r3)
			{
				server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 5000);
			}
			else if (r1 == 7 && r1 == r2 && r1 == r3)
			{
				server_MakePredefinedScroll(this.getPosition(), "sdragoon");
			}
			else if (r1 == 0)
			{
				server_DropCoins(this.getPosition() + Vec2f(0, -16.0f), 20);
			}

			/*	CBlob@ blob = server_CreateBlob( "mat_wood", this.getTeamNum(), this.getPosition() );
				if (blob !is null)
				{
					blob.server_SetQuantity( COST_WOOD_NURSERY/2 );
				}*/
		}
	}
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
