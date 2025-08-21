#include "Hitters.as"

#include "FireCommon.as"

void onInit(CBlob @ this)
{
	this.SetFacingLeft(XORRandom(128) > 64);

	this.getShape().getConsts().waterPasses = true;

	CShape @shape = this.getShape();
	shape.AddPlatformDirection(Vec2f(0, -1), 89, false);
	shape.SetRotationsAllowed(true);

	this.server_setTeamNum(-1); // allow anyone to break them
	this.set_TileType("background tile", CMap::tile_wood_back);

	if (this.getName() == "iron_platform")
	{

		if (getNet().isServer())
		{
			dictionary harvest;
			harvest.set('mat_ironingot', 1);
			this.set('harvest', harvest);
		}
	}

	MakeDamageFrame(this);
}

void onHealthChange(CBlob @ this, f32 oldHealth)
{
	f32 hp = this.getHealth();
	bool repaired = (hp > oldHealth);
	this.getSprite().PlaySound("/HitSolidMetal.ogg");
	MakeDamageFrame(this, repaired);
}

void MakeDamageFrame(CBlob @ this, bool repaired = false)
{
	f32 hp = this.getHealth();
	f32 full_hp = this.getInitialHealth();
	int frame_count = this.getSprite().animation.getFramesCount();
	int frame = frame_count - frame_count * (hp / full_hp);
	this.getSprite().animation.frame = frame;
}

void onSetStatic(CBlob @ this, const bool isStatic)
{
	if (!isStatic)
		return;

	this.getSprite().PlaySound("/HitSolidMetal.ogg");
}

bool canBePickedUp(CBlob @ this, CBlob @byBlob)
{
	return false;
}
