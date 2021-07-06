// Aphelion \\

#include "CreatureCommon.as";

const u16 ATTACK_FREQUENCY = 45;
const f32 ATTACK_DAMAGE = 2.0f;
const f32 ATTACK_DISTANCE = 0.5f;
const f32 DIG_RADIUS = 3.0f;
const f32 DIG_DAMAGE = 2.0f;

const int COINS_ON_DEATH = 200;

void onInit(CBlob@ this)
{
	this.set_u8("attack frequency", ATTACK_FREQUENCY);
	this.set_f32("attack damage", ATTACK_DAMAGE);
	this.set_f32("attack distance", ATTACK_DISTANCE);
	this.set_f32("dig radius", DIG_RADIUS);
	this.set_f32("dig damage", DIG_DAMAGE);		
	this.set_string("attack sound", "BossAttack");
	this.set_u16("coins on death", COINS_ON_DEATH);
	this.set_f32(target_searchrad_property, 512.0f);

	this.getShape().SetRotationsAllowed(false);

	this.getBrain().server_SetActive(true);

	this.set_f32("gib health", -3.0f);
    this.Tag("flesh");
	
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick( CBlob@ this )
{
	if (getNet().isClient() && XORRandom(1024) == 0)
	{
		this.getSprite().PlaySound("/BossIdle");
	}

	if (getNet().isServer() && getGameTime() % 10 == 0)
	{
		CBlob@ target = this.getBrain().getTarget();

		if (target !is null && this.getDistanceTo(target) < 128.0f)
		{
			this.Tag(chomp_tag);
		}
		else
		{
			this.Untag(chomp_tag);
		}

		this.Sync(chomp_tag, true);
	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if (damage >= 0.0f)
	{
		this.getSprite().PlaySound("/ZombieHit");
	}

	return damage;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (hitBlob !is null)
	{
		f32 forcePowX = 0;
		f32 forcePowY = 0;
		if (hitBlob.getPosition().x < this.getPosition().x)
			forcePowX = -1;
		else
			forcePowX = 1;
		if (hitBlob.getPosition().y < this.getPosition().y)
			forcePowY = -1;
		else
			forcePowY = 1;

		Vec2f forcePow = Vec2f (forcePowX, forcePowY);
		Vec2f force = forcePow * 260.0 * damage * 3.0f * 0.5;

		if (force.x < 0)
		{
			force.x = force.x * -1;
			force.x = XORRandom(force.x);
			force.x = force.x * -1;
		}
		else
			force.x = XORRandom(force.x);
		if (force.y < 0)
		{
			force.y = force.y * -1;
			force.y = XORRandom(force.y);
			force.y = force.y * -1;
		}
		else
			force.y = XORRandom(force.y);

		hitBlob.AddForce(force);
	}
}