// Aphelion \\

#include "CreatureCommon.as";

const int COINS_ON_DEATH = 25;

void onInit(CBlob@ this)
{
	TargetInfo[] infos;
	addTargetInfo(infos, "survivorplayer", 1.0f, true, true);
	addTargetInfo(infos, "mage", 0.9f);

	this.set("target infos", @infos);

	this.set_u16("coins on death", COINS_ON_DEATH);
	this.set_f32(target_searchrad_property, 512.0f);

	this.getSprite().SetEmitSound("Wings.ogg");
	this.getSprite().SetEmitSoundPaused(false);

	this.getSprite().PlayRandomSound("/GregCry");
	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);

	this.set_f32("gib health", 0.0f);
	this.Tag("flesh");
	this.Tag("zombie");
	this.Tag("enemy");
	this.Tag("gregs");
	
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
	this.server_SetTimeToDie(20);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null) return;

	// Ignore torches completely (and clear target if it was the torch)
	if (blob.getName() == "ruinstorch")
	{
		CBrain@ brain = this.getBrain();
		if (brain !is null && brain.getTarget() is blob)
			brain.SetTarget(null);
		return;
	}

	CBrain@ brain = this.getBrain();
	if (brain is null) return;

	if (blob is brain.getTarget())
	{
		this.server_AttachTo(blob, "PICKUP");
	}
}


f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if (damage >= 0.0f)
	{
	    this.getSprite().PlaySound( "/ZombieHit" );
    }
	return damage;
}

void onDie( CBlob@ this )
{
	this.getSprite().PlaySound("/GregRoar");	
}