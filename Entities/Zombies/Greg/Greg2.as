// Aphelion \\

#include "CreatureCommon.as";

const int COINS_ON_DEATH = 25;
const s16 GRAB_TIME = 120;
const s16 GRAB_COOLDOWN = 60;

void onInit(CBlob @ this)
{
	TargetInfo[] infos;
	addTargetInfo(infos, "survivorplayer", 1.0f, true, true);
	addTargetInfo(infos, "ruinstorch", 1.0f, true, true);
	addTargetInfo(infos, "stone_door", 0.9f);
	addTargetInfo(infos, "wooden_door", 0.9f);
	addTargetInfo(infos, "survivorbuilding", 0.6f, true);
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
       this.set_s16("grab timer", 0);
       this.set_s16("grab cooldown", 0);
       this.set_bool("was attached", false);

       this.getCurrentScript().runFlags |= Script::tick_not_attached;
       this.getCurrentScript().removeIfTag = "dead";
}

void onCollision(CBlob @ this, CBlob @blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null)
		return;

	// Ignore torches completely (and clear target if it was the torch)
	if (blob.getName() == "ruinstorch")
	{
		CBrain @brain = this.getBrain();
		if (brain !is null && brain.getTarget() is blob)
			brain.SetTarget(null);
		return;
	}

	CBrain @brain = this.getBrain();
	if (brain is null)
		return;

       if (blob is brain.getTarget() && !this.hasAttached() && this.get_s16("grab cooldown") <= 0)
       {
               this.server_AttachTo(blob, "PICKUP");
       }
}

void onTick(CBlob @ this)
{
       bool attached = this.hasAttached();
       bool wasAttached = this.get_bool("was attached");

       if (attached)
       {
               s16 grabTimer = this.get_s16("grab timer") + 1;
               if (grabTimer > GRAB_TIME)
               {
                       this.server_DetachAll();
                       attached = false;
                       this.set_s16("grab cooldown", GRAB_COOLDOWN);
                       grabTimer = 0;
               }
               this.set_s16("grab timer", grabTimer);
       }
       else
       {
               this.set_s16("grab timer", 0);
               s16 cooldown = this.get_s16("grab cooldown");
               if (cooldown > 0)
               {
                       this.set_s16("grab cooldown", cooldown - 1);
               }
       }

       if (!attached && wasAttached)
       {
               this.set_s16("grab cooldown", GRAB_COOLDOWN);
       }

       this.set_bool("was attached", attached);
}

f32 onHit(CBlob @ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob @hitterBlob, u8 customData)
{
	if (damage >= 0.0f)
	{
		this.getSprite().PlaySound("/ZombieHit");
	}
	return damage;
}

void onDie(CBlob @ this)
{
	this.getSprite().PlaySound("/GregRoar");
}