// Dorm

#include "WARCosts.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "ClassSelectMenu.as";
#include "StandardRespawnCommand.as";

void onInit( CBlob@ this )
{	 
	InitRespawnCommand(this);
	InitClasses(this);
	this.Tag("change class drop inventory");
	
	this.SetLight(true);
	this.SetLightRadius(128.0f );
	
	this.set_TileType("background tile", CMap::tile_wood_back);
	this.Tag("builder always hit");
	
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;	
}	  

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	u8 kek = caller.getTeamNum();	
	if (kek == 0)
	{
		if (caller.getTeamNum() == this.getTeamNum())
		{
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			CButton@ button = caller.CreateGenericButton("$change_class$", Vec2f(0, 0), this, SpawnCmd::buildMenu, "Change class", params);
		}
	}
}

void onInit(CSprite@ this)
{
	CSpriteLayer@ revivalorb = this.addSpriteLayer( "revivalorb","AltarOrb.png", 16,16 );
	
	if(revivalorb !is null)
	{
		Animation@ anim = revivalorb.addAnimation("default", 0, false);
		anim.AddFrame(0);
		revivalorb.SetAnimation(anim);
		revivalorb.SetOffset(Vec2f(0, 16));
		revivalorb.SetRelativeZ(0.1f);
	}
}

void onTick(CSprite@ this)
{
	//spin dat orb
	CSpriteLayer@ revivalorb = this.getSpriteLayer("revivalorb");

	if (revivalorb !is null)
	{
		revivalorb.SetFacingLeft(false);

		Vec2f around(0.5f, -0.5f);
		revivalorb.RotateBy(2.5f, around);
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == SpawnCmd::buildMenu || cmd == SpawnCmd::changeClass)
	{
		onRespawnCommand(this, cmd, params);
	}	
}

void onDie(CBlob@ this)
{
	if (!getNet().isServer())
		return;
	
	//int r = XORRandom(2);
	//if (r == 0)
	
	server_CreateBlob("lifeforce", -1, this.getPosition());
}

