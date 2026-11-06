// Aphelion (edited by Frikman)\\

#include "CreatureCommon.as";
#include "Hitters.as";

const u8 ATTACK_FREQUENCY = 60; // 30 = 1 second
const f32 ATTACK_DAMAGE = 0.25f;
const f32 ATTACK_DISTANCE = 1.0f;

const int COINS_ON_DEATH = 15;

void onInit(CBlob @ this)
{
	this.set_u8("attack frequency", ATTACK_FREQUENCY);
	this.set_f32("attack damage", ATTACK_DAMAGE);
	this.set_f32("attack distance", ATTACK_DISTANCE);
	this.set_u8("attack hitter", Hitters::fire);
	this.set_string("attack sound", "ZombieBite2");
	this.set_u16("coins on death", COINS_ON_DEATH);
	this.set_f32(target_searchrad_property, 512.0f);

	this.getSprite().SetEmitSound("Wings2.ogg");
	this.getSprite().SetEmitSoundPaused(false);

	this.getSprite().PlayRandomSound("/GasbagIdle");
	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);

	this.set_f32("gib health", 0.0f);
	this.Tag("flesh");

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";

	this.SetLight(true);
	this.SetLightRadius(32.0f);
	// this.SetLightColor(SColor(255, 120, 50, 140));
}

void onTick(CBlob @ this)
{
	if (getNet().isClient() && XORRandom(768) == 0)
	{
		this.getSprite().PlaySound("/GasbagIdle");
	}

	if (isServer() && getGameTime() % 10 == 0)
	{
		CBrain @brain = this.getBrain();
		CBlob @target = brain is null ? null : brain.getTarget();
		const bool chomping = target !is null && !target.hasTag("dead") &&
			this.getDistanceTo(target) < 72.0f;

		// All other zombies now sync their bite intent only on transitions.
		if (this.hasTag(chomp_tag) != chomping)
		{
			if (chomping)
				this.Tag(chomp_tag);
			else
				this.Untag(chomp_tag);
			this.Sync(chomp_tag, true);
		}
	}
}

f32 onHit(CBlob @ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob @hitterBlob, u8 customData)
{
	if (isClient() && damage > 0.0f)
	{
		CSprite @sprite = this.getSprite();
		if (sprite !is null)
			sprite.PlaySound("/SkeletonHit");
	}

	return damage;
}

void onDie(CBlob @ this)
{
	if (isClient())
	{
		CSprite @sprite = this.getSprite();
		if (sprite !is null)
			sprite.PlaySound("/SkeletonBreak1");
	}
}